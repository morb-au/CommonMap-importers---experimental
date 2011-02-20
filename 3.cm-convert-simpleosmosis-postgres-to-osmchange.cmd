REM  Yes this is a Windows command file.

REM  This command file does the import from the
REM  osmosis Simple Schema format into an
REM  osmChange document,
REM  suitable for using as the payload in an
REM  API 'upload' REST call.

REM  Don't forget to add a directory at '../for-upload'
REM  for the osmosis results to be placed into.

REM  Get parameters for the PostgreSQL database
CALL ../connect/destination.cmd

%OSMOSIS_DIRECTORY%\osmosis --read-pgsql host="localhost" database=%DATABASE_DESTINATION% user=%USER_DESTINATION% password=%PASSWORD_DESTINATION% --dataset-dump --read-xml file="null.osm" --derive-change --write-xml-change file="../for-upload/planetlet.change.osm"

echo 
pause
