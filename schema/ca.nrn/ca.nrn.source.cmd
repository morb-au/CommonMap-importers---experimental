REM  Yes this is a Windows command file.

REM  Called by '1.cm-convert-source-to-ogr-postgis.cmd'
REM  for settings specific to the work of an upstream
REM  provider (typically a Mapping Agency).

REM  This variant is specific to:
REM    Canada - GeoBase - National Road Network (c. 2010)


REM  Environment variables for the whole import chain -
REM  These are used to label the API changeset comments.
SET OGR_DATASOURCE_PROVIDER=Canada: GeoBase National Road Network
SET OGR_DATASOURCE_NAME=PE 9.0
SET OGR_DATASOURCE_FRIENDLY_NAME=Prince Edward Island

REM Ends.
