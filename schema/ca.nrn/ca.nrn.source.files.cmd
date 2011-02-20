REM  Yes this is a Windows command file.

REM  Called by '1.cm-convert-source-to-ogr-postgis.cmd'
REM  for settings specific to the work of an upstream
REM  provider (typically a Mapping Agency).

REM  This variant is specific to:
REM    Canada - GeoBase - National Road Network (c. 2010)

REM  Note, according to GeoBase 2.0 Data Product Specfifications
REM  for the NRN, (section 4.2.1) the Street Name, Place name
REM  and Address Range (STRPLANAME, ALTNAMELINK, ADDRANGE files)
REM  have already been denormalised into the Road Segments layer.



REM Saskatchewan

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_sk\NRN_SK_4_0_BLKPASSAGE.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_sk\NRN_SK_4_0_FERRYSEG.shp"
REM Give the next step a hint for motorway exits
"%PATH_TO_PSQL%" -d %PSQL_DBNAME_ORIGIN% -U %PSQL_USERNAME_ORIGIN% -c "ALTER TABLE nrn_sk_4_0_ferryseg ADD COLUMN cm_feature_type varchar(30)"
"%PATH_TO_PSQL%" -d %PSQL_DBNAME_ORIGIN% -U %PSQL_USERNAME_ORIGIN% -c "UPDATE nrn_sk_4_0_ferryseg SET cm_feature_type='Ferry Route'"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_sk\NRN_SK_4_0_JUNCTION.shp"
REM Give the next step a hint for motorway exits
"%PATH_TO_PSQL%" -d %PSQL_DBNAME_ORIGIN% -U %PSQL_USERNAME_ORIGIN% -c "ALTER TABLE nrn_sk_4_0_junction ADD COLUMN cm_feature_type varchar(30)"
"%PATH_TO_PSQL%" -d %PSQL_DBNAME_ORIGIN% -U %PSQL_USERNAME_ORIGIN% -c "UPDATE nrn_sk_4_0_junction SET cm_feature_type='Exit' WHERE exitnbr <> 'None'"


"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_sk\NRN_SK_4_0_ROADSEG.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_sk\NRN_SK_4_0_TOLLPOINT.shp"
pause


REM Alberta

REM "%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_ab\NRN_AB_7_1_BLKPASSAGE.shp"

REM "%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_ab\NRN_AB_7_1_FERRYSEG.shp"

REM "%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_ab\NRN_AB_7_1_JUNCTION.shp"
REM Give the next step a hint for motorway exits
"%PATH_TO_PSQL%" -d %PSQL_DBNAME_ORIGIN% -U %PSQL_USERNAME_ORIGIN% -c "ALTER TABLE nrn_ab_7_1_junction ADD COLUMN cm_feature_type varchar(30)"
"%PATH_TO_PSQL%" -d %PSQL_DBNAME_ORIGIN% -U %PSQL_USERNAME_ORIGIN% -c "UPDATE nrn_ab_7_1_junction SET cm_feature_type='Exit' WHERE exitnbr <> 'None'"
pause

REM "%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_ab\NRN_AB_7_1_ROADSEG.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_ab\NRN_AB_7_1_TOLLPOINT.shp"



REM British Columbia

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_bc\NRN_BC_7_0_BLKPASSAGE.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_bc\NRN_BC_7_0_FERRYSEG.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_bc\NRN_BC_7_0_JUNCTION.shp"

REM "%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_bc\NRN_BC_7_0_ROADSEG.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_bc\NRN_BC_7_0_TOLLPOINT.shp"



REM Prince Edward Island

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_pe\NRN_PE_9_0_BLKPASSAGE.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_pe\NRN_PE_9_0_FERRYSEG.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_pe\NRN_PE_9_0_JUNCTION.shp"

REM "%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_pe\NRN_PE_9_0_ROADSEG.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_pe\NRN_PE_9_0_TOLLPOINT.shp"

