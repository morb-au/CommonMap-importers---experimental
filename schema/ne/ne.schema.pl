#!/usr/bin/perl

# Schema for "2.cm-convert-ogr-postgis-to-simpleosmosis-postgres.pl"
# This version deals with the Natural Earth (c. 2010) schema.

# Brendan Morley, 2009-12-30

# In the spirit of the CC BY licence used by CommonMap, this script is
# published under the BSD licence.


##
## SETTINGS
##

  ### START OF DATASET-SPECIFIC SCHEMA TRANSLATIONS


  ## Tables in the origin database (ogr PostGIS format) to scan
  @tables_origin = (
    '10m_land',
    '10m_minor_islands',
    
#    '10m_admin_0_countries',
    '10m_admin_0_scale_ranks_with_minor_islands',
    '10m_admin_0_breakaway_disputed_areas_scale_ranks',
    '10m_admin_1_states_provinces_shp',
    
    '10m_populated_places',
    '10m_urban_areas',
    '10m_roads_north_america',
    '10m_railroads',
    '10m_us_parks_area',  # TODO
    '10m_us_parks_line',  # TODO
    '10m_us_parks_point', # TODO
    
    '10m_rivers_north_america',
    '10m_rivers_europe',
    '10m_lakes_north_america',
    '10m_lakes_europe',
    
    '10m_playas',

    );


  ## For source tables, if there is a value
  #  available in the table's column as named on the Left-Hand Side,
  #  copy the value to a destination key named on the Right-Hand Side.
  #
  #  Note:
  #  The value will be modified (not just copied) if the LHS here is also
  #  listed in the LHS of %{ $attribute_translate{}{} } futher below.
  #
  %attributes_origin = (
     'ogc_fid'             => 'ne:fid',

#     # '10m_admin_0_countries'
#     'country'             => 'name',

     # '10m_admin_0_scale_ranks_with_minor-islands'
     'subunit'             => 'name',
                              # consecutive 'is_in' entries are prepended
     'sov'                 => 'is_in',
     'admin_0'             => 'is_in',
     'mapunit'             => 'is_in',

     # '10m_admin_0_breakaway_disputed_areas_scale_ranks'
     'comment'             => 'description',
     'name_alt'            => 'alt_name',
     'namegroup'           => 'is_in',

     # '10m_admin_1_states_provinces_shp'
     'name_0'              => 'is_in',
     'name_1'              => 'name',
     'varname_1'           => 'alt_name',
     'remarks_1'           => 'note',
     
     # '10m_populated_places'
     'name'                => 'name',
     'namealt'             => 'alt_name',
                              # consecutive 'is_in' entries are prepended
     'sov_a3'              => 'is_in',
#     'adm0name'            => 'is_in',       
     'adm1name'            => 'is_in',
     'namepar'             => 'is_in',       # More like the "administrative authority", it seems.
     
     # '10m_roads_north_america'
                              # consecutive 'ref' entries are prepended
     'number'              => 'ref',
     'prefix'              => 'ref',
                              # consecutive 'is_in' entries are prepended
     'country'             => 'is_in',       
     'state'               => 'is_in',

     # '10m_railroads'
#     'sov_a3'              => 'is_in',
# TODO: Let these be per-table
# rather than global to the whole import.
# Unfortunately Natural Earth's data dictionary
# is a bit inconsisent across tables.

     # '10m_rivers_north_america'
     # '10m_rivers_europe'
     'name1'               => 'name',

     # '10m_lakes_north_america'
     # '10m_lakes_europe'
#     'name1'               => 'name',
     'altitude'             => 'ele',    # TODO: Is this in metres?
     
     # '10m_playas'
#     'name1'               => 'name',

     
     #
     # these ones are just for passthrough to %{$attribute_translate} below.
     #
     'featurecla'          => 'featurecla',

     # '10m_admin_1_states_provinces_shp'
     'engtype_1'           => 'engtype_1',

    );
   

  ## Street number translations
  #  These are treated specially to build
  #  offset lines to their corresponding street ways.
  @street_number_attributes = ( 
#                                'l_hnumf',     # FROMLEFT
#                                'r_hnumf',     # FROMRIGHT
#                                'l_hnuml',     # TOLEFT
#                                'r_hnuml',     # TORIGHT
#                                'l_stname_c',  # NAMELEFT
#                                'r_stname_c'   # NAMERIGHT
                              );
                              
  # value used in source data if there is no street number.
  $street_number_nil_value = 0;

   
  ## A series of attribute value translations 
  # Left-Hand Side = attribute name as specified in the source table,
  #                  and its value to match for its corresponding RHS here
  #                  to be substituted instead.
  # Right-Hand Side = tags/value pairs to use for the substitution into the destination.
  #
  #  Note:
  #  The attribute name must also be
  #  listed in the RHS of %attributes_origin futher above,
  #  Otherwise it will not be copied from source to
  #  destination at all.

  %{ $attribute_translate{'featurecla'}{'Land'} }                      = ( 'natural'     => 'land' );
  %{ $attribute_translate{'featurecla'}{'Minor island'} }              = ( 'natural'     => 'land' );

  %{ $attribute_translate{'featurecla'}{'Admin-0 scale ranks'} }       = ( 'place'       => 'city' );

  %{ $attribute_translate{'featurecla'}{'Admin-0 map-subunits'} }      = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => '2' );
  %{ $attribute_translate{'featurecla'}{'Indeterminant'} }             = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => 'indeterminant' );
  %{ $attribute_translate{'featurecla'}{'Overlay'} }                   = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => 'overlay' );
  %{ $attribute_translate{'featurecla'}{'Breakaway and disputed'} }    = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => 'disputed - breakaway' );
  %{ $attribute_translate{'featurecla'}{'Claim area'} }                = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => 'disputed - claimed' );

  %{ $attribute_translate{'featurecla'}{'Admin-0 capital'} }           = ( 'place'       => 'city' );
  %{ $attribute_translate{'featurecla'}{'Admin-0 capital alt'} }       = ( 'place'       => 'city' );
  %{ $attribute_translate{'featurecla'}{'Admin-0 region capital'} }    = ( 'place'       => 'city' );
  %{ $attribute_translate{'featurecla'}{'Admin-1 capital'} }           = ( 'place'       => 'city' );
  %{ $attribute_translate{'featurecla'}{'Admin-1 region capital'} }    = ( 'place'       => 'city' );
  %{ $attribute_translate{'featurecla'}{'Populated place'} }           = ( 'place'       => 'town' );
  %{ $attribute_translate{'featurecla'}{'Scientific station'} }        = ( 'place'       => 'locality',
                                                                            'note'        => 'Scientific station' );

  %{ $attribute_translate{'engtype_1'}{'Administrative County'} }      = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => '6' );
  %{ $attribute_translate{'engtype_1'}{'Administrative State'} }       = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => '4' );
  %{ $attribute_translate{'engtype_1'}{'Administrative Zone'} }        = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => '4' );
  %{ $attribute_translate{'engtype_1'}{'Arrondissement'} }             = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => '7' );
  %{ $attribute_translate{'engtype_1'}{'Department'} }                 = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => '4' );
# Incomplete allowed values for Level 1 admin areas
  %{ $attribute_translate{'engtype_1'}{'Province'} }                   = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => '4' );
  %{ $attribute_translate{'engtype_1'}{'State'} }                      = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => '4' );
  %{ $attribute_translate{'engtype_1'}{'Territory'} }                  = ( 'type'        => 'boundary',
                                                                            'boundary'    => 'administrative',
                                                                            'admin_level' => '4' );

 
  %{ $attribute_translate{'type'}{'Ferry'} }                           = ( 'route'       => 'ferry' );
  %{ $attribute_translate{'type'}{'Freeway'} }                         = ( 'highway'     => 'motorway' );
  %{ $attribute_translate{'type'}{'Other Paved'} }                     = ( 'highway'     => 'unclassified' );
  %{ $attribute_translate{'type'}{'Primary'} }                         = ( 'highway'     => 'primary' );
  %{ $attribute_translate{'type'}{'Secondary'} }                       = ( 'highway'     => 'secondary' );
  %{ $attribute_translate{'type'}{'Tollway'} }                         = ( 'highway'     => 'motorway',
                                                                            'toll'        => 'yes' );
  %{ $attribute_translate{'type'}{'Unpaved'} }                         = ( 'highway'     => 'unclassified',
                                                                            'surface'     => 'unpaved' );
  %{ $attribute_translate{'type'}{'Winter'} }                          = ( 'highway'     => 'unclassified',
                                                                            'winter_road' => 'yes' );

  %{ $attribute_translate{'class'}{'Federal'} }                        = ( 'note'        => 'Federal Highway' );
  %{ $attribute_translate{'class'}{'State'} }                          = ( 'note'        => 'State Highway' );
  %{ $attribute_translate{'class'}{'Interstate'} }                     = ( 'note'        => 'Interstate Highway' );
  %{ $attribute_translate{'class'}{'U/C'} }                            = ( 'highway'     => 'construction' );

  %{ $attribute_translate{'divided'}{'Divided'} }                      = ( 'divided'     => 'yes',
                                                                            'oneway'      => 'no' );
  %{ $attribute_translate{'divided'}{'Undivided'} }                    = ( 'divided'     => 'no',
                                                                            'oneway'      => 'no' );


  %{ $attribute_translate{'featurecla'}{'Railroad'} }                  = ( 'railway'     => 'yes' );

  %{ $attribute_translate{'featurecla'}{'Urban area'} }                = ( 'landuse'     => 'built',        # New in CommonMap
                                                                            'place'       => 'town' );       # New combo in CommonMap

  %{ $attribute_translate{'featurecla'}{'River'} }                     = ( 'waterway'    => 'river' );
  %{ $attribute_translate{'featurecla'}{'Intermittent River'} }        = ( 'waterway'    => 'river',
                                                                            'intermittent'=> 'yes' );        # New in CommonMap
  %{ $attribute_translate{'featurecla'}{'River (Intermittent)'} }      = ( 'waterway'    => 'river',
                                                                            'intermittent'=> 'yes' );        # New in CommonMap
  %{ $attribute_translate{'featurecla'}{'Lake Centerline'} }           = ( 'waterway'    => 'network' );    # New in CommonMap
  %{ $attribute_translate{'featurecla'}{'River (Intermittent)'} }      = ( 'waterway'    => 'network',
                                                                            'intermittent'=> 'yes' );        # New in CommonMap
  %{ $attribute_translate{'featurecla'}{'Lake'} }                      = ( 'natural'     => 'water' );
  %{ $attribute_translate{'featurecla'}{'Reservoir'} }                 = ( 'natural'     => 'water',
                                                                            'landuse'     => 'reservoir' );
  %{ $attribute_translate{'featurecla'}{'Alkaline Lake'} }             = ( 'natural'     => 'water',
                                                                            'salt'        => 'alkaline' );   # New in CommonMap
  %{ $attribute_translate{'featurecla'}{'Playa'} }                     = ( 'natural'     => 'water',
                                                                            'intermittent'=> 'yes',          # New in CommonMap
                                                                            'salt'        => 'yes' );        # New in CommonMap

  %{ $attribute_translate{'featurecla'}{'National Park Service'} }     = ( 'boundary'    => 'national_park' );


  ## static tags in the destination, to always be applied.
  #  This will typically be to apply the attribution and licence clause.
  %attributes_tattoo = (
     'by'                    => 'Natural Earth',
     'licence'               => 'PD',
     'accuracy:planimetric'  => '5600',   # Assuming scaling from 250k to 10m, c.f. Geoscience Australia planimetric accuracy
    );

  ## The affine transformation to apply to source geometry
  #  You may want to use this is the source x and y order is reversed, etc.
  #  It gets used to in the SELECT clause of PostGIS statements,
  #  therefore any valid PostGIS column expressions are allowed here.
#  $affine = "affine(wkb_geometry, 0, 1, 1, 0, 0, 0)"; # hack, swaps x and y
  $affine = "wkb_geometry"; # unhack, the passthrough version


# END OF DATASET-SPECIFIC SCHEMA TRANSLATIONS

 
##
## ENDS
##
