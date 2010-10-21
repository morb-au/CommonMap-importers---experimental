REM  Yes this is a Windows command file.

REM  This command file does the import from the
REM  osmosis Simple Schema format into an
REM  osmChange document,
REM  suitable for using as the payload in an
REM  API 'upload' REST call.

REM  Don't forget to add a directory at '../for-upload'
REM  for the osmosis results to be placed into.

REM  Run it with the nickname of your source schema
REM  as your command line parameter, e.g. "ca.nrn"
REM  for the Canadian National Road Network.

REM  Get environment variables for this import chain
CALL schema/%1/%1.source.cmd

REM  Get parameters for the OpenStreetMap/CommonMap API
CALL ../connect/api.cmd

SET JAVACMD_OPTIONS=-Xmx512m

%OSMOSIS_DIRECTORY%\osmosis --read-xml-change file="../for-upload/planetlet.change.osm" --upload-xml-change server=%API_SERVER_URL% user=%API_USER% password=%API_PASSWORD% comment="Automated import of %OGR_DATASOURCE_PROVIDER% geodata - %OGR_DATASOURCE_NAME% (%OGR_DATASOURCE_FRIENDLY_NAME%)

pause

