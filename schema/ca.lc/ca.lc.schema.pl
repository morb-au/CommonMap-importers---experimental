#!/usr/bin/perl

# Schema for "2.cm-convert-ogr-postgis-to-simpleosmosis-postgres.pl"
# This version deals with the Canadian Land Cover Circa 2000 schema.

# Brendan Morley, 2011-02-18

# In the spirit of the CC BY licence used by CommonMap, this script is
# published under the BSD licence.


##
## SETTINGS
##

  ### START OF DATASET-SPECIFIC SCHEMA TRANSLATIONS


  ## Tables in the origin database (ogr PostGIS format) to scan
  @tables_origin = (

    'lcc2000',

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
     'accuracy'            => 'accuracy:planimetric',
     'acqtech'             => 'source',
     'provider'            => 'ca.geobase:provider',
     'datasetnam'          => 'ca.geobase.lc:dataset',
     
     # these ones are just for passthrough to %{$attribute_translate} below.

     'covtype'             => 'covtype',

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

  %{ $attribute_translate{'ca.geobase:provider'}{'1'} }          = ( 'ca.geobase:provider' => 'Other' );
  %{ $attribute_translate{'ca.geobase:provider'}{'2'} }          = ( 'ca.geobase:provider' => 'Federal' );
  %{ $attribute_translate{'ca.geobase:provider'}{'3'} }          = ( 'ca.geobase:provider' => 'Provincial/Territorial' );
  %{ $attribute_translate{'ca.geobase:provider'}{'4'} }          = ( 'ca.geobase:provider' => 'Municipal' );

  #   0 = No Data
  #  10 = Unclassified
  #  11 = Cloud
  #  12 = Shadow
  #  20 = Water (do not import as part of LCC2000, let NHN handle it)
  #  30 = Barren / Non-vegetated (not distinguished enough to assign a CM tag)
  #  31 = Snow / Ice
  %{ $attribute_translate{'covtype'}{'31'} }       = ( 'natural'   => 'glacier'       );
  #  32 = Rock / Rubble
  %{ $attribute_translate{'covtype'}{'31'} }       = ( 'natural'   => 'scree'       );
  #  33 = Exposed (not distinguished enough to assign a CM tag)
  #  34 = Developed
  %{ $attribute_translate{'covtype'}{'31'} }       = ( 'landuse'   => 'built'       );
  #  35 = Sparsely vegetated bedrock (no matching CM tag)
  #  36 = Sparsely vegetated till - colluvium (no matching CM tag)
  #  37 = Bare soil with cryptogam crust - frost boils (no matching CM tag)
  #  40 = Bryoids (no matching CM tag)
  #  50 = Shrubland
  %{ $attribute_translate{'covtype'}{'50'} }       = ( 'natural'   => 'scrub'       );
  #  51 = Shrub tall
  %{ $attribute_translate{'covtype'}{'51'} }       = ( 'natural'   => 'scrub'       );
  #  52 = Shrub low
  %{ $attribute_translate{'covtype'}{'52'} }       = ( 'natural'   => 'scrub'       );
  #  53 = Prostrate dwarf shrub
  %{ $attribute_translate{'covtype'}{'53'} }       = ( 'natural'   => 'scrub'       );
  #  80 = Wetland
  %{ $attribute_translate{'covtype'}{'80'} }       = ( 'natural'   => 'wetland'       );
  #  81 = Wetland - Treed
  %{ $attribute_translate{'covtype'}{'81'} }       = ( 'natural'   => 'wetland',
                                                        'wetland'   => 'swamp'       );
  #  82 = Wetland - Shrub
  %{ $attribute_translate{'covtype'}{'82'} }       = ( 'natural'   => 'wetland',
                                                        'wetland'   => 'swamp'         );
  #  83 = Wetland - Herb
  %{ $attribute_translate{'covtype'}{'83'} }       = ( 'natural'   => 'wetland'       );
  # 100 = Herb
  %{ $attribute_translate{'covtype'}{'100'} }       = ( 'landuse'   => 'meadow'       );
  # 101 = Tussock graminoid tundra
  %{ $attribute_translate{'covtype'}{'101'} }       = ( 'natural'   => 'scrub'       );
  # 102 = Wet sedge
  %{ $attribute_translate{'covtype'}{'102'} }       = ( 'natural'   => 'wetland',
                                                         'landuse'   => 'meadow'       );
  # 103 = Moist to dry non-tussock graminoid / dwarf shrub tundra
  %{ $attribute_translate{'covtype'}{'103'} }       = ( 'natural'   => 'scrub'       );
  # 104 = Dry graminoid prostrate dwarf shrub tundra
  %{ $attribute_translate{'covtype'}{'104'} }       = ( 'natural'   => 'scrub'       );
  # 110 = Grassland
  %{ $attribute_translate{'covtype'}{'110'} }       = ( 'landuse'   => 'meadow'       );
  # 120 = Cultivated Agricultural Land (note, could be 'farmland' or 'orchard')
  %{ $attribute_translate{'covtype'}{'120'} }       = ( 'landuse'   => 'farmland'       );
  # 121 = Annual Cropland (note, could be 'farmland', 'vineyard' or 'orchard')
  %{ $attribute_translate{'covtype'}{'121'} }       = ( 'landuse'   => 'farmland'       );
  # 122 = Perennial Cropland and Pasture
  %{ $attribute_translate{'covtype'}{'120'} }       = ( 'landuse'   => 'farmland'       );

  # 200 = Forest / Tree classes
  %{ $attribute_translate{'covtype'}{'200'} }       = ( 'natural'   => 'wood'        );

  # 210 = Coniferous Forest
  %{ $attribute_translate{'covtype'}{'210'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'coniferous'  );
  # 211 = Coniferous Dense
  %{ $attribute_translate{'covtype'}{'211'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'coniferous',
                                                         'coverage'  => 'dense'       );
  # 212 = Coniferous Open
  %{ $attribute_translate{'covtype'}{'212'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'coniferous',
                                                         'coverage'  => 'open'        );
  # 213 = Coniferous Sparse
  %{ $attribute_translate{'covtype'}{'213'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'coniferous',
                                                         'coverage'  => 'sparse'      );

  # 220 = Deciduous Forest
  %{ $attribute_translate{'covtype'}{'220'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'deciduous'  );
  # 221 = Broadleaf Dense
  %{ $attribute_translate{'covtype'}{'221'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'deciduous',
                                                         'coverage'  => 'dense'       );
  # 222 = Broadleaf Open
  %{ $attribute_translate{'covtype'}{'222'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'deciduous',
                                                         'coverage'  => 'open'        );
  # 223 = Broadleaf Sparse
  %{ $attribute_translate{'covtype'}{'223'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'deciduous',
                                                         'coverage'  => 'sparse'      );

  # 230 = Mixed Forest
  %{ $attribute_translate{'covtype'}{'230'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'mixed'  );
  # 231 = Mixedwood Dense
  %{ $attribute_translate{'covtype'}{'231'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'mixed',
                                                         'coverage'  => 'dense'       );
  # 232 = Mixedwood Open
  %{ $attribute_translate{'covtype'}{'232'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'mixed',
                                                         'coverage'  => 'open'        );
  # 233 = Mixedwood Sparse
  %{ $attribute_translate{'covtype'}{'233'} }       = ( 'natural'   => 'wood',
                                                         'wood'      => 'mixed',
                                                         'coverage'  => 'sparse'      );

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
