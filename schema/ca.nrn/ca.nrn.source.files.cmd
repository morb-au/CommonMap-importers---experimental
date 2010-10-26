REM  Yes this is a Windows command file.

REM  Called by '1.cm-convert-source-to-ogr-postgis.cmd'
REM  for settings specific to the work of an upstream
REM  provider (typically a Mapping Agency).

REM  This variant is specific to:
REM    Canada - GeoBase - National Road Network (c. 2010)

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\nrn_rrn_pe\NRN_PE_9_0_ROADSEG.shp"
