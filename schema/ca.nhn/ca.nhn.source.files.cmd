REM  Yes this is a Windows command file.

REM  Called by '1.cm-convert-source-to-ogr-postgis.cmd'
REM  for settings specific to the work of an upstream
REM  provider (typically a Mapping Agency).

REM  This variant is specific to:
REM    Canada - GeoBase - National Hydro Network (c. 2011)


REM Pacific Drainage Area > Vancouver Island > Southern Vancouver Island
SET NHN_DATASETNAME=08HA0X3
SET NHN_DATASETVERSION=1_0

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hd_island_2 -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HD_ISLAND_2.shp"
"%PATH_TO_PSQL%" -d %PSQL_DBNAME_ORIGIN% -U %PSQL_USERNAME_ORIGIN% -c "ALTER TABLE nhn_hd_island_2 ADD COLUMN cm_feature_type varchar(30)"
"%PATH_TO_PSQL%" -d %PSQL_DBNAME_ORIGIN% -U %PSQL_USERNAME_ORIGIN% -c "UPDATE nhn_hd_island_2 SET cm_feature_type='Island'"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hd_manmade_0 -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HD_MANMADE_0.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hd_manmade_1 -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HD_MANMADE_1.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hd_manmade_2 -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HD_MANMADE_2.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hd_obstacle_0  -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HD_OBSTACLE_0.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hd_slwater_1   -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HD_SLWATER_1.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hd_waterbody_2 -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HD_WATERBODY_2.shp"


"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hn_bank_1        -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HN_BANK_1.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hn_delimiter_1   -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HN_DELIMITER_1.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hn_hydrojunct_0  -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HN_HYDROJUNCT_0.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hn_littoral_1    -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HN_LITTORAL_1.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_hn_nlflow_1      -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_HN_NLFLOW_1.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_to_namedfea_2    -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_TO_NAMEDFEA_2.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln nhn_workunit_limit_2 -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nhn_rhn_%NHN_DATASETNAME%_shp_en\NHN_%NHN_DATASETNAME%_%NHN_DATASETVERSION%_WORKUNIT_LIMIT_2.shp"

