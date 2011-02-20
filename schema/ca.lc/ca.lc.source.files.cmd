REM  Yes this is a Windows command file.

REM  Called by '1.cm-convert-source-to-ogr-postgis.cmd'
REM  for settings specific to the work of an upstream
REM  provider (typically a Mapping Agency).

REM  This variant is specific to:
REM    Canada - GeoBase - Land Cover Circa 2000


SET LCC2000_DATASETNAME=092H
SET LCC2000_DATASETVERSION=2_0

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nln lcc2000 -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\lc_%LCC2000_DATASETNAME%_shp_en\LCC2000-V_%LCC2000_DATASETNAME%_%LCC2000_DATASETVERSION%.shp"
