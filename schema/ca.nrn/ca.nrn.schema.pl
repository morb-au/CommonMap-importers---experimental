#!/usr/bin/perl

# Schema for "2.cm-convert-ogr-postgis-to-simpleosmosis-postgres.pl"
# This version deals with the National Road Network (c. 2010) schema.

# Brendan Morley, 2009-12-30

# In the spirit of the CC BY licence used by CommonMap, this script is
# published under the BSD licence.


##
## SETTINGS
##

  ### START OF DATASET-SPECIFIC SCHEMA TRANSLATIONS


  ## Tables in the origin database (ogr PostGIS format) to scan
  @tables_origin = (
    'nrn_pe_9_0_roadseg'
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
     'roadsegid'           => 'ca.geobase.nrn.pe:id',
     'nid'                 => 'ca.gc.rncan:nid',
#     'l_stname_c'          => 'name',
     'r_stname_c'          => 'name',
     'rtnumber1'           => 'ref',
     'accuracy'            => 'accuracy:planimetric',
     'acqtech'             => 'source',
     'provider'            => 'ca.geobase.nrn.pe:provider',
     'nbrlanes'            => 'lanes',
     
     # these ones are just for passthrough to %{$attribute_translate} below.
#     'code'                => 'code',
     'roadclass'           => 'roadclass',
     'pavsurf'             => 'pavsurf',
     'unpavsurf'           => 'unpavsurf',
     'structtype'          => 'structtype',
     'strunameen'          => 'alt_name:en',
     'strunamefr'          => 'alt_name:fr',

     # derived attributes     
     'addr:housenumber'    => 'addr:housenumber',
     'addr:interpolation'  => 'addr:interpolation',
     'addr:street'         => 'addr:street',
     'name'                => 'name',

# debugging fields (traceable through the lifecycle of the dataset upload).
'testbuild'           => 'testbuild',
'test'                => 'test',
    );
   

  ## Street number translations
  #  These are treated specially to build
  #  offset lines to their corresponding street ways.
  @street_number_attributes = ( 
                                'l_hnumf',     # FROMLEFT
                                'r_hnumf',     # FROMRIGHT
                                'l_hnuml',     # TOLEFT
                                'r_hnuml',     # TORIGHT
                                'l_stname_c',  # NAMELEFT
                                'r_stname_c'   # NAMERIGHT
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

  %{ $attribute_translate{'roadclass'}{'Freeway'} }               = ( 'highway'   => 'motorway' );
  %{ $attribute_translate{'roadclass'}{'Expressway / Highway'} }  = ( 'highway'   => 'trunk' );
  %{ $attribute_translate{'roadclass'}{'Arterial'} }              = ( 'highway'   => 'primary' );
  %{ $attribute_translate{'roadclass'}{'Collector'} }             = ( 'highway'   => 'secondary' );
  %{ $attribute_translate{'roadclass'}{'Local / Street'} }        = ( 'highway'   => 'residential' );
  %{ $attribute_translate{'roadclass'}{'Local / Strata'} }        = ( 'highway'   => 'residential',
                                                                       'access'    => 'permissive' );
  %{ $attribute_translate{'roadclass'}{'Local / Unknown'} }       = ( 'highway'   => 'residential',
                                                                       'access'    => 'unknown' );
  %{ $attribute_translate{'roadclass'}{'Alleyway / Lane'} }       = ( 'highway'   => 'service' );

  # Cannot distinguish primary_link, secondary_link etc.
  # Therefore a 'Ramp' will be translated into a generic 'road'.
  # Manual intervention will be required at a later stage
  # of the import.
  %{ $attribute_translate{'roadclass'}{'Ramp'} }                  = ( 'highway'   => 'road' );

  %{ $attribute_translate{'roadclass'}{'Resource / Recreation'} } = ( 'highway'   => 'unclassified' );
  %{ $attribute_translate{'roadclass'}{'Rapid Transit'} }         = ( 'highway'   => 'unclassified',
                                                                       'access'    => 'psv' );
  %{ $attribute_translate{'roadclass'}{'Service Lane'} }          = ( 'highway'   => 'service' );
  %{ $attribute_translate{'roadclass'}{'Winter'} }                = ( 'highway'   => 'track',
                                                                       'surface'   => 'ice_road' );

  %{ $attribute_translate{'pavsurf'}{'Flexible'} }                = ( 'surface'   => 'asphalt' );
  %{ $attribute_translate{'pavsurf'}{'Rigid'} }                   = ( 'surface'   => 'concrete' );
  %{ $attribute_translate{'pavsurf'}{'Blocks'} }                  = ( 'surface'   => 'cobblestone' );
  %{ $attribute_translate{'pavsurf'}{'Unknown'} }                 = ( 'surface'   => 'paved' );
  # 'None' = magic text for 'n/a'
  %{ $attribute_translate{'pavsurf'}{'None'} }                    = ( );

  %{ $attribute_translate{'unpavsurf'}{'Gravel'} }                = ( 'surface'   => 'asphalt' );
  %{ $attribute_translate{'unpavsurf'}{'Dirt'} }                  = ( 'surface'   => 'concrete' );
  %{ $attribute_translate{'unpavsurf'}{'Unknown'} }               = ( 'surface'   => 'unpaved' );
  # 'None' = magic text for 'n/a'
  %{ $attribute_translate{'unpavsurf'}{'None'} }                  = ( );

  %{ $attribute_translate{'structtype'}{'Bridge'} }               = ( 'layer'     => '1',
                                                                       'bridge'    => 'yes' );
  %{ $attribute_translate{'structtype'}{'Bridge covered'} }       = ( 'layer'     => '1',
                                                                       'bridge'    => 'yes' );
  %{ $attribute_translate{'structtype'}{'Bridge moveable'} }      = ( 'layer'     => '1',
                                                                       'bridge'    => 'yes' );
  %{ $attribute_translate{'structtype'}{'Bridge unknown'} }       = ( 'layer'     => '1',
                                                                       'bridge'    => 'yes' );
  %{ $attribute_translate{'structtype'}{'Tunnel'} }               = ( 'layer'     => '-1',
                                                                       'tunnel'    => 'yes' );
  %{ $attribute_translate{'structtype'}{'Snowshed'} }             = ( 'layer'     => '-1',
                                                                       'tunnel'    => 'yes',
                                                                       'snowshed'  => 'yes' );
  %{ $attribute_translate{'structtype'}{'Dam'} }                  = ( 'layer'     => '1',
                                                                       'waterway'  => 'dam' );
  # 'None' = magic text for 'n/a'
  %{ $attribute_translate{'structtype'}{'None'} }                 = ( );


  # 'Unknown' = magic text for 'n/a'
  %{ $attribute_translate{'name'}       {'Unknown'} } = ( );
  # 'None' = magic text for 'n/a'
  %{ $attribute_translate{'ref'}        {'None'} }    = ( );
  # 'None' = magic text for 'n/a'
  %{ $attribute_translate{'alt_name:en'}{'None'} }    = ( );
  # 'None' = magic text for 'n/a'
  %{ $attribute_translate{'alt_name:fr'}{'None'} }    = ( );


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
