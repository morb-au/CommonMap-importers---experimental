REM  Yes this is a Windows command file.

REM  This command file does the import from your Mapping Agency's
REM  source datasets (as long as OGR understands it)
REM  into an OGR PostGIS format.

REM  Run it with the nickname of your source schema
REM  as your command line parameter, e.g. "ca.nrn"
REM  for the Canadian National Road Network.

REM  Get environment variables for this import chain
CALL schema/%1/%1.source.cmd

REM  Get origin dataset path details for this import chain
CALL ../connect/schema/origin.%1.cmd

REM  Get parameters for the PostgreSQL database
CALL ../connect/origin.cmd

REM  Environment variables just for ogr2ogr 
SET PGCLIENTENCODING=LATIN1

REM  Do the actual transformation of the files from
REM  upstream source format to PostGIS format
CALL schema/%1/%1.source.files.cmd

echo 
pause

REM ends.
