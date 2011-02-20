#!/usr/bin/perl

# Schema for "2.cm-convert-ogr-postgis-to-simpleosmosis-postgres.pl"
# This version deals with the National Hydro Network (c. 2011) schema.

# Brendan Morley, 2011-02-14

# In the spirit of the CC BY licence used by CommonMap, this script is
# published under the BSD licence.


##
## SETTINGS
##

  ### START OF DATASET-SPECIFIC SCHEMA TRANSLATIONS


  ## Tables in the origin database (ogr PostGIS format) to scan
  @tables_origin = (

    'nhn_hd_island_2',
    'nhn_hd_manmade_0',
    'nhn_hd_manmade_1',
    'nhn_hd_manmade_2',
    'nhn_hd_obstacle_0',
    'nhn_hd_slwater_1',
    'nhn_hd_waterbody_2',
    'nhn_to_namedfea_2',

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
     'nid'                 => 'ca.gc.rncan:nid',
     'name'                => 'name',
     'name_1'              => 'name',
     'name_2'              => 'name',
     'accuracy'            => 'accuracy:planimetric',
     'acqtech'             => 'source',
     'provider'            => 'ca.geobase.nhn:provider',
     'datasetnam'          => 'ca.geobase.nhn:dataset',
     
     'lakename_1'          => 'name',
     'lakename_2'          => 'name',

     'rivname_1'           => 'alt_name',
     'rivname_2'           => 'alt_name',


     # these ones are just for passthrough to %{$attribute_translate} below.

     'coastal'             => 'coastal',
     'definition'          => 'definition',
     'isolated'            => 'isolated',
     'permanency'          => 'permanency',
     'sand'                => 'sand',
     'status'              => 'status',
     'type'                => 'type',

     'cm_feature_type'     => 'cm_feature_type',
     

     # derived attributes     
#     'addr:housenumber'    => 'addr:housenumber',
#     'addr:interpolation'  => 'addr:interpolation',
#     'addr:street'         => 'addr:street',
#     'name'                => 'name',

# debugging fields (traceable through the lifecycle of the dataset upload).
'testbuild'           => 'testbuild',
'test'                => 'test',
    );
   

#  ## Street number translations
#  #  These are treated specially to build
#  #  offset lines to their corresponding street ways.
#  @street_number_attributes = ( 
#                                'l_hnumf',     # FROMLEFT
#                                'r_hnumf',     # FROMRIGHT
#                                'l_hnuml',     # TOLEFT
#                                'r_hnuml',     # TORIGHT
#                                'l_stname_c',  # NAMELEFT
#                                'r_stname_c'   # NAMERIGHT
#                              );
                              
#  # value used in source data if there is no street number.
#  $street_number_nil_value = 0;

   
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

  %{ $attribute_translate{'ca.geobase.nhn:provider'}{'1'} }       = ( 'ca.geobase.nhn:provider' => 'Other' );
  %{ $attribute_translate{'ca.geobase.nhn:provider'}{'2'} }       = ( 'ca.geobase.nhn:provider' => 'Federal' );
  %{ $attribute_translate{'ca.geobase.nhn:provider'}{'3'} }       = ( 'ca.geobase.nhn:provider' => 'Provincial/Territorial' );
  %{ $attribute_translate{'ca.geobase.nhn:provider'}{'4'} }       = ( 'ca.geobase.nhn:provider' => 'Municipal' );

  %{ $attribute_translate{'source'}{'-1'} }                       = ( 'source'   => 'unknown'       );
  %{ $attribute_translate{'source'}{'0'} }                        = ( 'source'   => 'none'          );
  %{ $attribute_translate{'source'}{'1'} }                        = ( 'source'   => 'other'         );
  %{ $attribute_translate{'source'}{'2'} }                        = ( 'source'   => 'gps'           );
  %{ $attribute_translate{'source'}{'3'} }                        = ( 'source'   => 'orthoimage'    );
  %{ $attribute_translate{'source'}{'4'} }                        = ( 'source'   => 'orthophoto'    );
  %{ $attribute_translate{'source'}{'5'} }                        = ( 'source'   => 'vector_data'   );
  %{ $attribute_translate{'source'}{'6'} }                        = ( 'source'   => 'paper_map'     );
  %{ $attribute_translate{'source'}{'7'} }                        = ( 'source'   => 'field_survey'  );


  # Special case for Ferry Routes
  %{ $attribute_translate{'cm_feature_type'}{'Island'} }          = ( 'natural'   => 'land'  );

  # "coastal" is a marginal attribute to propagate into CommonmMap but we'll do it anyway.
  %{ $attribute_translate{'coastal'}{'-1'} }                      = ( 'coastal'   => 'unknown' );
  %{ $attribute_translate{'coastal'}{'0'} }                       = ( 'coastal'   => 'no'      );
  %{ $attribute_translate{'coastal'}{'1'} }                       = ( 'coastal'   => 'yes'     );

  # "sand" is a marginal attribute to propagate into CommonmMap but we'll do it anyway.
  %{ $attribute_translate{'sand'}{'-1'} }                         = ( 'sand'      => 'unknown' );
  %{ $attribute_translate{'sand'}{'1'} }                          = ( 'sand'      => 'no'      );
  %{ $attribute_translate{'sand'}{'2'} }                          = ( 'sand'      => 'yes'     );


  # "isolated" is a marginal attribute to propagate into CommonmMap but we'll do it anyway.
  %{ $attribute_translate{'isolated'}{'0'} }                      = ( 'network:isolated'  => 'no'  );
  %{ $attribute_translate{'isolated'}{'1'} }                      = ( 'network:isolated'  => 'yes' );

  # "permanency" is a marginal attribute to propagate into CommonmMap but we'll do it anyway.
  %{ $attribute_translate{'permanency'}{'-1'} }                   = ( 'permanent'  => 'unknown'  );
  %{ $attribute_translate{'permanency'}{'1'} }                    = ( 'permanent'  => 'no'  );
  %{ $attribute_translate{'permanency'}{'2'} }                    = ( 'permanent'  => 'yes' );

  %{ $attribute_translate{'definition'}{'0'} }                    = ( 'waterway'       => 'unknown'    );
  %{ $attribute_translate{'definition'}{'1'} }                    = ( 'waterway'       => 'canal'      );
  %{ $attribute_translate{'definition'}{'2'} }                    = ( 'waterway'       => 'conduit'    );  # New in CommonMap
  %{ $attribute_translate{'definition'}{'3'} }                    = ( 'waterway'       => 'ditch'      );
  %{ $attribute_translate{'definition'}{'4'} }                    = ( 'natural'        => 'water'      );
  %{ $attribute_translate{'definition'}{'5'} }                    = ( 'natural'        => 'water',
                                                                       'landuse'        => 'reservoir'  );
  %{ $attribute_translate{'definition'}{'6'} }                    = ( 'waterway'       => 'stream'     );
  %{ $attribute_translate{'definition'}{'7'} }                    = ( 'waterway'       => 'river',
                                                                       'tidal'          => 'yes'        );  # New in CommonMap
  %{ $attribute_translate{'definition'}{'8'} }                    = ( 'landuse'        => 'reservoir',
                                                                       'reservoir_type' => 'tailings'   );  # NHN says "Liquid Waste"
  %{ $attribute_translate{'definition'}{'9'} }                    = ( 'natural'        => 'water'      );
  %{ $attribute_translate{'definition'}{'10'} }                   = ( 'natural'        => 'water'      );


  # "abandoned" is a marginal attribute to propagate into CommonmMap but we'll do it anyway.
  %{ $attribute_translate{'status'}{'-1'} }                         = ( 'abandoned'      => 'unknown' );
  %{ $attribute_translate{'status'}{'1'} }                          = ( 'abandoned'      => 'no'      );
  %{ $attribute_translate{'status'}{'2'} }                          = ( 'abandoned'      => 'yes'     );


  %{ $attribute_translate{'type'}{'-1'} }                           = ( 'man_made'       => 'unknown'      );
  %{ $attribute_translate{'type'}{'0'} }                            = ( 'man_made'       => 'yes'          );
  %{ $attribute_translate{'type'}{'1'} }                            = ( 'waterway'       => 'dam'          );
  # ...............................'2' has no equivalent in CommonMap/OSM
  %{ $attribute_translate{'type'}{'3'} }                            = ( 'mooring'        => 'yes'          );
  %{ $attribute_translate{'type'}{'4'} }                            = ( 'man_made'       => 'groyne'       );
  %{ $attribute_translate{'type'}{'5'} }                            = ( 'embankment'     => 'levee'        );  # New in CommonMap
  %{ $attribute_translate{'type'}{'6'} }                            = ( 'waterway'       => 'lock_gate'    );
  %{ $attribute_translate{'type'}{'7'} }                            = ( 'leisure'        => 'slipway'      );
  %{ $attribute_translate{'type'}{'8'} }                            = ( 'waterway'       => 'fish_ladder'  ); # New in CommonMap
  %{ $attribute_translate{'type'}{'9'} }                            = ( 'waterway'       => 'boatyard'     );


  # 'Unknown' = magic text for 'n/a'
  %{ $attribute_translate{'name'}       {'Unknown'} } = ( );
  # 'None' = magic text for 'n/a'
  %{ $attribute_translate{'name'}       {'None'} }    = ( );


  ## static tags in the destination, to always be applied.
  #  This will typically be to apply the attribution and licence clause.
  %attributes_tattoo = (
     'by'             => 'Natural Resources Canada',
     'licence'        => 'CC BY (compatible)',
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
