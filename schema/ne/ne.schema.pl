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
    '10m_land'
    );


  ## For source tables, if there is a value
  #  available in the table's column as named on the Left-Hand Side,
  #  copy the value to a destination key named on the Right-Hand Side.
  #
  #  Note:
  #  The value will be modified (not just copied) if the RHS here is also
  #  listed in the LHS of %{ $attribute_translate{}{} } futher below.
  #
  %attributes_origin = (
     'ogc_fid'             => 'ne:fid',
     
     # these ones are just for passthrough to %{$attribute_translate} below.
     'featurecla'          => 'class',

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
  # Left-Hand Side = attribute name as specified in the RHS of %attributes_origin further above,
  #                  and its value to match for its corresponding RHS here
  #                  to be substituted instead.
  # Right-Hand Side = tags/value pairs to use for the substitution into the destination.
  #
  #  Note:
  #  The attribute name must also be
  #  listed in the RHS of %attributes_origin futher above,
  #  Otherwise it will not be copied from source to
  #  destination at all.

  %{ $attribute_translate{'class'}{'Land'} }                      = ( 'natural'   => 'land' );


  ## static tags in the destination, to always be applied.
  #  This will typically be to apply the attribution and licence clause.
  %attributes_tattoo = (
     'by'             => 'Natural Earth',
     'licence'        => 'PD',
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
