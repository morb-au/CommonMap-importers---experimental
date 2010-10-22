#!/bin/bash

# This file is partnered with '3a.cm-convert-simpleosmosis-to-psql-copy-files.pl'
#   at the client end.  It receives psql COPY files and throws them into
#   the core database.  It should run on the same machine as the postmaster
#   daemon for the core database, for performance reasons.

CHANGESET_UPLOAD_BASE=/tmp/commonmap/bulk-uploads
CHANGESET_UPLOAD_PATH=$CHANGESET_UPLOAD_BASE/for-upload
CHANGESET_SQL_PATH=$CHANGESET_UPLOAD_BASE/sql

echo "Starting bulk importer pass on $CHANGESET_UPLOAD_BASE"

# Make sure only one copy runs at a time
LOCKFILE=/tmp/4a.cm-psql-copy-files-to-osm-api.bash.lock
 
if [ -f $LOCKFILE ]; then
  if [ "$(ps -p `cat $LOCKFILE` | wc -l)" -gt 1 ]; then
    # process is still running
    echo "Locked"
    exit 1
  else
    # process not running, but lock file not deleted?
    echo "WARNING: Previous execution did not run to completion"
    rm $LOCKFILE
  fi
fi
echo $$ > $LOCKFILE 


# Now for the script proper

# Add PostgreSQL 9.0 path for access to pg_config
# Should have no side-effect for PostgreSQL 8.x-only systems
PATH=/usr/pgsql-9.0/bin:$PATH 


cd $CHANGESET_UPLOAD_BASE


#
# Go through each file in the queue
#
for BZ2_UPLOAD in cm.*.bz2
do

echo "Processing $BZ2_UPLOAD"


# Clear out detritus from previous runs
#  otherwise will confuse 'ls $CHANGESET_UPLOAD_PATH' below
echo "Clearing out old files..."
echo "... Removing $CHANGESET_UPLOAD_PATH"
rm -rf $CHANGESET_UPLOAD_PATH
echo "... Removing $CHANGESET_SQL_PATH/upload.*.sql"
rm $CHANGESET_SQL_PATH/upload.*.sql

echo "Unpacking BZip2 file..."
tar -jxvf $BZ2_UPLOAD

for UPLOAD_CHANGESET in $( ls $CHANGESET_UPLOAD_PATH )
do

mkdir -p $CHANGESET_SQL_PATH

echo "Creating SQL script for import at $CHANGESET_SQL_PATH/upload.$UPLOAD_CHANGESET.sql"

cat <<EOL > $CHANGESET_SQL_PATH/upload.$UPLOAD_CHANGESET.sql
 
BEGIN;

COPY changesets FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.changeset.tsv';
COPY changeset_tags FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.changeset_tags.tsv';

COPY current_nodes FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.current_nodes.tsv';
COPY current_node_tags FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.current_node_tags.tsv';
COPY nodes FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.nodes.tsv';
COPY node_tags FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.node_tags.tsv';

COPY current_ways FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.current_ways.tsv';
COPY current_way_nodes FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.current_way_nodes.tsv';
COPY current_way_tags FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.current_way_tags.tsv';
COPY ways FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.ways.tsv';
COPY way_nodes FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.way_nodes.tsv';
COPY way_tags FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.way_tags.tsv';

COPY current_relations FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.current_relations.tsv';
COPY current_relation_members FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.current_relation_members.tsv';
COPY current_relation_tags FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.current_relation_tags.tsv';
COPY relations FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.relations.tsv';
COPY relation_members FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.relation_members.tsv';
COPY relation_tags FROM '$CHANGESET_UPLOAD_PATH/$UPLOAD_CHANGESET/cm.$UPLOAD_CHANGESET.relation_tags.tsv';

COMMIT;

EOL


chown -R postgres:postgres $CHANGESET_UPLOAD_BASE

echo "Running the SQL script for import at $CHANGESET_SQL_PATH/upload.$UPLOAD_CHANGESET.sql"

su - postgres -c "psql -d commonmap_pr -U commonmap_pr < $CHANGESET_SQL_PATH/upload.$UPLOAD_CHANGESET.sql"  

echo "Done the SQL script for import at $CHANGESET_SQL_PATH/upload.$UPLOAD_CHANGESET.sql"

done

echo "Removing $BZ2_UPLOAD"
rm $BZ2_UPLOAD

done

echo "Completed bulk importer pass on $CHANGESET_UPLOAD_BASE"

rm $LOCKFILE 

#
# ENDS.
#
