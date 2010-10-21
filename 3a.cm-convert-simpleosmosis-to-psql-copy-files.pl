#!/usr/bin/perl -w

# Script to convert data 
# from the PostgreSQL simple schema format understood by osmosis
# to a series of TSV files suitable for bulk loading
# by PostgreSQL (psql \copy or similar) in the OSM API schema (v0.6)

# This script is designed to optimise the performance
# of bulk imports compared to the well-known HTTP API backed by rails.

# It should get also get around the 50,000 element limit of the
# standard API.

# Note: You should create a directory at '../bulk-upload-next-ids'
#   so that this script can store its state between runs.

# You'll need access to libarchive, e.g. from
#   http://gnuwin32.sourceforge.net/packages/libarchive.htm 

# Brendan Morley, 2010-06-09

# In the spirit of the CC-BY licence used by CommonMap, this script is
# published under the BSD licence.

##
## TODOs
##
# 1. Track new high water ids for next pass


##
## INCLUDES
##

use DBI;

require '../connect/destination.pl';

##
## SETTINGS
##

  ## The "high water mark" of existing ids in the destination
  #  core database.
  #  This must be different to any existing ID and
  #  any likely autoincrementing IDs
  $new_hw_id_changeset = $hw_id_changeset = 2;
  $new_hw_id_node      = $hw_id_node      = 2;
  $new_hw_id_way       = $hw_id_way       = 2;
  $new_hw_id_relation  = $hw_id_relation  = 2;
  
  ## See if this script has been run before and if so,
  #  freshen the ID high waters.
  $next_ids_file = '../bulk-upload-next-ids/next_ids.pl';
  require $next_ids_file;
  
  ## Find this figure by looking up
  #  'db/migrate/050_prepare_for_merge_replication.rb'
  #  in the CommonMap rails git repository.
  $hw_id_increment_by = 8;

  
  ## Connection details for source database (osmosis Simple Schema format)
  #  as sourced from '../connect/destination.pl'
  $conn_simpleosmosis     = $conn_destination;
  $user_simpleosmosis     = $user_destination;
  $password_simpleosmosis = $password_destination;

  
  ## Binding details for destination psql
  #  as sourced from '../connect/destination.pl'
  $user_id_for_changeset = $commonmap_user_id;
  
  
  ## Destination directory for PostgreSQL COPY files
  $psql_copy_path = '../for-upload/'.$hw_id_changeset;
  
##
## CODE
##

  sub escape_tsv_text
  {
    my($text) = @_;
    
#    $text =~ s/\"/\\\"/g;  # escape quotes
#    $text =~ s/\,/\\\,/g;  # escape commas
    
#    return '"'.$text.'"';
     return $text;
  }

  # ported from rails/lib/quad_tile/quad_tile.h
  sub xy2tile
  {
    my($x, $y) = @_;

    my($tile) = 0;

    for (my $i = 15; $i >= 0; $i--)
    { 
      $tile = ($tile << 1) | (($x >> $i) & 1);
      $tile = ($tile << 1) | (($y >> $i) & 1);
    }

    return $tile;
  }

  # ported from rails/lib/quad_tile/quad_tile.h
  sub lon2x
  {
    my($lon) = @_;
    return sprintf( '%d', (($lon + 180.0) * 65535.0 / 360.0) );
  }

  # ported from rails/lib/quad_tile/quad_tile.h
  sub lat2y
  {
    my($lat) = @_;
    return sprintf( '%d', (($lat + 90.0) * 65535.0 / 180.0) );
  }

  # ported from rails/lib/quad_tile/quad_tile.c
  sub tile_for_point
  {
    my($lat, $lon) = @_;

    my($x) = &lon2x($lon);
    my($y) = &lat2y($lat);

    return (&xy2tile($x, $y));
  }

  
  # expands the global bbox if necessary
  sub expand_bbox
  {
    my($lat, $lon) = @_;
    
    if ((!defined $min_lat) or ($min_lat > $lat))
    {
      $min_lat = $lat;
    }
    if ((!defined $max_lat) or ($max_lat < $lat))
    {
      $max_lat = $lat;
    }
    if ((!defined $min_lon) or ($min_lon > $lon))
    {
      $min_lon = $lon;
    }
    if ((!defined $max_lon) or ($max_lon < $lon))
    {
      $max_lon = $lon;
    }
  }

  sub get_changeset
  {
    my($sth_changeset) = $dbh_simpleosmosis->prepare(
        'select NOW() as created_at, NOW() as closed_at'
      );
      
    $sth_changeset->execute;
    
    my($ref) = $sth_changeset->fetchrow_hashref;
    my($created_at) = $ref->{'created_at'};
    my($closed_at)  = $ref->{'closed_at'};

    my($dest_id) = $hw_id_changeset;
    my($user_id) = $user_id_for_changeset;
    
    print CHANGESET
      join("\t",
        $dest_id,
        $user_id,
        $created_at,
        $min_lat,
        $max_lat,
        $min_lon,
        $max_lon,
        $closed_at,
        $num_changes,
      ).
      "\n";
  }


  sub get_changeset_tags
  {

    my($dest_id) = $hw_id_changeset;
    my($created_by) = escape_tsv_text('3a.cm-convert-simpleosmosis-to-psql-copy-files.pl');
    my($comment) = escape_tsv_text(
                    "Automated import of ".
                    $ENV{'OGR_DATASOURCE_PROVIDER'}.
                    " geodata - ".
                    $ENV{'OGR_DATASOURCE_NAME'}.
                    " (".
                    $ENV{'OGR_DATASOURCE_FRIENDLY_NAME'}.
                    ")"
                    );
                    
    print CHANGESET_TAGS
      join("\t",
        $dest_id,
        'created_by',
        $created_by,
      ).
      "\n";

    print CHANGESET_TAGS
      join("\t",
        $dest_id,
        'comment',
        $comment,
      ).
      "\n";

  }
  

  sub get_nodes
  {
    my($sth_nodes) = $dbh_simpleosmosis->prepare(
        'select id, y(geom) as latitude, X(geom) as longitude, NOW() as now '.
        'from nodes'
      );
      
    $sth_nodes->execute;
    
    while (my $ref = $sth_nodes->fetchrow_hashref)
    {
      my($dest_id)   = $hw_id_node + ($ref->{'id'} * -($hw_id_increment_by));
      my($latitude)  = sprintf( '%ld', ($ref->{'latitude'}  * 10000000000000000) );
      my($longitude) = sprintf( '%ld', ($ref->{'longitude'} * 10000000000000000) );
      my($timestamp) = $ref->{'now'};
      my($tile)      = &tile_for_point($ref->{'latitude'},
                                        $ref->{'longitude'});

      if ($dest_id > $new_hw_id_node)
      {
        $new_hw_id_node = $dest_id;
      }
                  
      print CURRENT_NODES
        join("\t",
          $dest_id,
          $latitude,
          $longitude,
          $hw_id_changeset,
          'T',                # visible
          $timestamp,
          $tile,              # tile
          1,                  # version
        ).
        "\n";

      print NODES
        join("\t",
          $dest_id,
          $latitude,
          $longitude,
          $hw_id_changeset,
          'T',                # visible
          $timestamp,
          $tile,              # tile
          1,                  # version
        ).
        "\n";
        
      &expand_bbox($latitude, $longitude);
        
      $num_changes++;  
    }  
  }


  sub get_node_tags
  {
    my($sth_node_tags) = $dbh_simpleosmosis->prepare(
        'select node_id, k, v '.
        'from node_tags'
      );
      
    $sth_node_tags->execute;
    while (my $ref = $sth_node_tags->fetchrow_hashref)
    {
      my($dest_id)   = $hw_id_node + ($ref->{'node_id'} * -($hw_id_increment_by));
      my($k)         = escape_tsv_text($ref->{'k'});
      my($v)         = escape_tsv_text($ref->{'v'});
                  
      print CURRENT_NODE_TAGS
        join("\t",
          $dest_id,
          $k,
          $v,
        ).
        "\n";

      print NODE_TAGS
        join("\t",
          $dest_id,
          1,                  # version
          $k,
          $v,
        ).
        "\n";

    }  
  }


  sub get_ways
  {
    my($sth_ways) = $dbh_simpleosmosis->prepare(
        'select id, NOW() as now '.
        'from ways'
      );
      
    $sth_ways->execute;
    
    while (my $ref = $sth_ways->fetchrow_hashref)
    {
      my($dest_id)   = $hw_id_way + ($ref->{'id'} * -($hw_id_increment_by));
      my($timestamp) = $ref->{'now'};

      if ($dest_id > $new_hw_id_way)
      {
        $new_hw_id_way = $dest_id;
      }

      print CURRENT_WAYS
        join("\t",
          $dest_id,
          $hw_id_changeset,
          $timestamp,
          'T',                # visible
          1,                  # version
        ).
        "\n";

      print WAYS
        join("\t",
          $dest_id,
          $hw_id_changeset,
          $timestamp,
          1,                  # version
          'T',                # visible
        ).
        "\n";

      $num_changes++;  
    }  
  }


  sub get_way_tags
  {
    my($sth_way_tags) = $dbh_simpleosmosis->prepare(
        'select way_id, k, v '.
        'from way_tags'
      );
      
    $sth_way_tags->execute;
    while (my $ref = $sth_way_tags->fetchrow_hashref)
    {
      my($dest_id)   = $hw_id_way + ($ref->{'way_id'} * -($hw_id_increment_by));
      my($k)         = escape_tsv_text($ref->{'k'});
      my($v)         = escape_tsv_text($ref->{'v'});
                  
      print CURRENT_WAY_TAGS
        join("\t",
          $dest_id,
          $k,
          $v,
        ).
        "\n";
                  
      print WAY_TAGS
        join("\t",
          $dest_id,
          $k,
          $v,
          1,                  # version
        ).
        "\n";

    }  
  }


  sub get_way_nodes
  {
    my($sth_way_nodes) = $dbh_simpleosmosis->prepare(
        'select way_id, node_id, sequence_id '.
        'from way_nodes'
      );
      
    $sth_way_nodes->execute;
    while (my $ref = $sth_way_nodes->fetchrow_hashref)
    {
      my($dest_id)     = $hw_id_way  + ($ref->{'way_id'} * -($hw_id_increment_by));
      my($node_id)     = $hw_id_node + ($ref->{'node_id'} * -($hw_id_increment_by));
      my($sequence_id) = $ref->{'sequence_id'};
                  
      print CURRENT_WAY_NODES
        join("\t",
          $dest_id,
          $node_id,
          $sequence_id,
        ).
        "\n";
                  
      print WAY_NODES
        join("\t",
          $dest_id,
          $node_id,
          1,                  # version
          $sequence_id,
        ).
        "\n";

    }  
  }


  sub get_relations
  {
    my($sth_relations) = $dbh_simpleosmosis->prepare(
        'select id, NOW() as now '.
        'from relations'
      );
      
    $sth_relations->execute;
    
    while (my $ref = $sth_relations->fetchrow_hashref)
    {
      my($dest_id)   = $hw_id_relation + ($ref->{'id'} * -($hw_id_increment_by));
      my($timestamp) = $ref->{'now'};

      if ($dest_id > $new_hw_id_relation)
      {
        $new_hw_id_relation = $dest_id;
      }

      print CURRENT_RELATIONS
        join("\t",
          $dest_id,
          $hw_id_changeset,
          $timestamp,
          'T',                # visible
          1,                  # version
        ).
        "\n";

      print RELATIONS
        join("\t",
          $dest_id,
          $hw_id_changeset,
          $timestamp,
          1,                  # version
          'T',                # visible
        ).
        "\n";

      $num_changes++;  
    }  
  }


  sub get_relation_tags
  {
    my($sth_relation_tags) = $dbh_simpleosmosis->prepare(
        'select relation_id, k, v '.
        'from relation_tags'
      );
      
    $sth_relation_tags->execute;
    while (my $ref = $sth_relation_tags->fetchrow_hashref)
    {
      my($dest_id)   = $hw_id_relation + ($ref->{'relation_id'} * -($hw_id_increment_by));
      my($k)         = escape_tsv_text($ref->{'k'});
      my($v)         = escape_tsv_text($ref->{'v'});
                  
      print CURRENT_RELATION_TAGS
        join("\t",
          $dest_id,
          $k,
          $v,
        ).
        "\n";
                  
      print RELATION_TAGS
        join("\t",
          $dest_id,
          $k,
          $v,
          1,                  # version
        ).
        "\n";

    }  
  }


  sub get_relation_members
  {
    my($sth_relation_members) = $dbh_simpleosmosis->prepare(
        'select relation_id, member_id, member_type, member_role, sequence_id '.
        'from relation_members'
      );
      
    $sth_relation_members->execute;
    while (my $ref = $sth_relation_members->fetchrow_hashref)
    {
      my($dest_id)     = $hw_id_relation + ($ref->{'relation_id'} * -($hw_id_increment_by));
      my($member_type);
      my($member_id);
      if ($ref->{'member_type'} eq 'N')
      {   
        $member_type = 'Node';
        $member_id = $hw_id_node + ($ref->{'member_id'} * -($hw_id_increment_by));
      }
      elsif ($ref->{'member_type'} eq 'W')
      {
        $member_type = 'Way';
        $member_id = $hw_id_way + ($ref->{'member_id'} * -($hw_id_increment_by));
      }
      elsif ($ref->{'member_type'} eq 'R')
      {
        $member_type = 'Relation';
        $member_id = $hw_id_relation + ($ref->{'member_id'} * -($hw_id_increment_by));
      }
      my($member_role) = escape_tsv_text($ref->{'member_role'});
      my($sequence_id) = $ref->{'sequence_id'};
                  
      print CURRENT_RELATION_MEMBERS
        join("\t",
          $dest_id,
          $member_type,
          $member_id,
          $member_role,
          $sequence_id,
        ).
        "\n";

      print RELATION_MEMBERS
        join("\t",
          $dest_id,
          $member_type,
          $member_id,
          $member_role,
          1,                  # version
          $sequence_id,
        ).
        "\n";

    }  
  }


  sub generate_changeset
  {
    open(CHANGESET,      '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.changeset.tsv');
    open(CHANGESET_TAGS, '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.changeset_tags.tsv');
    
    &get_changeset;
    &get_changeset_tags;
    
    close(CHANGESET);
    close(CHANGESET_TAGS);
  }
  
  sub generate_nodes
  {
    open(CURRENT_NODES,     '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.current_nodes.tsv');
    open(NODES,             '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.nodes.tsv');
    open(CURRENT_NODE_TAGS, '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.current_node_tags.tsv');
    open(NODE_TAGS,         '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.node_tags.tsv');
    
    &get_nodes;
    &get_node_tags;
        
    close(CURRENT_NODES);
    close(NODES);
    close(CURRENT_NODE_TAGS);
    close(NODE_TAGS);
  }
  
  sub generate_ways
  {
    open(CURRENT_WAYS,      '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.current_ways.tsv');
    open(WAYS,              '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.ways.tsv');
    open(CURRENT_WAY_TAGS,  '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.current_way_tags.tsv');
    open(WAY_TAGS,          '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.way_tags.tsv');
    open(CURRENT_WAY_NODES, '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.current_way_nodes.tsv');
    open(WAY_NODES,         '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.way_nodes.tsv');
    
    &get_ways;
    &get_way_tags;
    &get_way_nodes;
    
    
    close(CURRENT_WAYS);
    close(WAYS);
    close(CURRENT_WAY_TAGS);
    close(WAY_TAGS);
    close(CURRENT_WAY_NODES);
    close(WAY_NODES);
  }
  
  sub generate_relations
  {
    open(CURRENT_RELATIONS,        '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.current_relations.tsv');
    open(RELATIONS,                '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.relations.tsv');
    open(CURRENT_RELATION_TAGS,    '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.current_relation_tags.tsv');
    open(RELATION_TAGS,            '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.relation_tags.tsv');
    open(CURRENT_RELATION_MEMBERS, '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.current_relation_members.tsv');
    open(RELATION_MEMBERS,         '>'.$psql_copy_path.'/cm.'.$hw_id_changeset.'.relation_members.tsv');
    
    &get_relations;
    &get_relation_tags;
    &get_relation_members;
    
    
    close(CURRENT_RELATIONS);
    close(RELATIONS);
    close(CURRENT_RELATION_TAGS);
    close(RELATION_TAGS);
    close(CURRENT_RELATION_MEMBERS);
    close(RELATION_MEMBERS);
  }

  sub db_connect
  {
    $dbh_simpleosmosis = DBI->connect($conn_simpleosmosis,
                                      $user_simpleosmosis, 
                                      $password_simpleosmosis, 
      {
        RaiseError => 1, 
        AutoCommit => 0,
        ChopBlanks => 1
      })
          or die "Can't connect to $conn_simpleosmosis: $DBI::errstr";
  }
  
  sub db_disconnect
  {
    $dbh_simpleosmosis->disconnect;
  }

##
## MAIN CODE
##

  my($min_lat);
  my($max_lat);
  my($min_lon);
  my($max_lon);
  my($num_changes);

  print "Connecting to database...\n";
  &db_connect;
  
  mkdir($psql_copy_path);
  
  print "Generating nodes...\n";
  &generate_nodes;

  print "Generating ways...\n";
  &generate_ways;

  print "Generating relations...\n";
  &generate_relations;
  
  print "Generating changeset...\n";
  &generate_changeset;
  

  # BZip2 them all up  
  system '"'.$ENV{PATH_TO_TAR}.'"'." -jcvf $psql_copy_path/cm.$hw_id_changeset.bz2 $psql_copy_path/*";


  print "Disconnecting from database...\n";
  &db_disconnect;

  print "Done.\n";
  
  
  print "Use these values for next import:\n";
  print '  $new_hw_id_changeset = $hw_id_changeset = '.($new_hw_id_changeset+($hw_id_increment_by)).";\n";
  print '  $new_hw_id_node      = $hw_id_node      = '.($new_hw_id_node+($hw_id_increment_by)).";\n";
  print '  $new_hw_id_way       = $hw_id_way       = '.($new_hw_id_way+($hw_id_increment_by)).";\n";
  print '  $new_hw_id_relation  = $hw_id_relation  = '.($new_hw_id_relation+($hw_id_increment_by)).";\n";

  
  open(NEXT, '>>'.$next_ids_file);

  print NEXT "\n# New next-IDs created as a result of a run at ".localtime()."\n";

  print NEXT '  $new_hw_id_changeset = $hw_id_changeset = '.($new_hw_id_changeset+($hw_id_increment_by)).";\n";
  print NEXT '  $new_hw_id_node      = $hw_id_node      = '.($new_hw_id_node+($hw_id_increment_by)).";\n";
  print NEXT '  $new_hw_id_way       = $hw_id_way       = '.($new_hw_id_way+($hw_id_increment_by)).";\n";
  print NEXT '  $new_hw_id_relation  = $hw_id_relation  = '.($new_hw_id_relation+($hw_id_increment_by)).";\n";

  print NEXT "#\n";
  print NEXT "# DO NOT ADJUST THESE VALUES UNLESS YOU HAVE CONSULTED THE OWNER OF THE API!\n";
  print NEXT "#\n\n";
  
  close(NEXT);
  
##
## ENDS
##
