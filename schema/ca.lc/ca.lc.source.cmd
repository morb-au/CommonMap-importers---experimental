REM  Yes this is a Windows command file.

REM  Called by '1.cm-convert-source-to-ogr-postgis.cmd'
REM  for settings specific to the work of an upstream
REM  provider (typically a Mapping Agency).

REM  This variant is specific to:
REM    Canada - GeoBase - Land Cover Circa 2000


REM  Environment variables for the whole import chain -
REM  These are used to label the API changeset comments.
SET OGR_DATASOURCE_PROVIDER=Canada: Land Cover Circa 2000
SET OGR_DATASOURCE_NAME=092H
SET OGR_DATASOURCE_FRIENDLY_NAME=NTDB sheet 092H

REM Ends.
