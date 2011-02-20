REM  Yes this is a Windows command file.

REM  Called by '1.cm-convert-source-to-ogr-postgis.cmd'
REM  for settings specific to the work of an upstream
REM  provider (typically a Mapping Agency).

REM  This variant is specific to:
REM    Natural Earth (c. 2010)

REM Cultural Layers.

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_admin_0_scale_ranks_with_minor-islands.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_admin_1_states_provinces_shp.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_admin_0_breakaway_disputed_areas_scale_ranks.shp"


"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_us_parks_area.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_us_parks_line.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_us_parks_point.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_urban_areas.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_populated_places.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_roads_north_america.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_cultural\10m_railroads.shp"

REM Physical Layers.

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_land.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_minor_islands.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_rivers_north_america.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_rivers_europe.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_lakes_north_america.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_lakes_europe.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_glaciated_areas.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_antarctic_ice_shelves_polys.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_reefs.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_playas.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_geography_marine_polys.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_geography_regions_polys.shp"
"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_geography_regions_points.shp"

"%OGR_DIRECTORY%\ogr2ogr" -skipfailures -overwrite -nlt GEOMETRY -f PostgreSQL PG:%CONNECTION_ORIGIN% "%SOURCE_DIRECTORY%\10m_physical\10m_geography_regions_elevation_points.shp"


