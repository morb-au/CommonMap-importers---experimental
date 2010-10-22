REM  Yes this is a Windows command file.

REM  Called by '1.cm-convert-source-to-ogr-postgis.cmd'
REM  for settings specific to the work of an upstream
REM  provider (typically a Mapping Agency).

REM  This variant is specific to:
REM    Natural Earth (c. 2010)

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_land.shp"
