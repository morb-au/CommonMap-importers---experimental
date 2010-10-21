#!/usr/bin/perl

# Script to convert data 
# from the PostGIS format understood by ogr2ogr, 
# to the PostgreSQL simple schema format understood by osmosis

# Brendan Morley, 2009-12-30

# In the spirit of the CC BY licence used by CommonMap, this script is
# published under the BSD licence.

#
# The purpose of this script is to assist in getting OGR-readable databases
# into the OSM API Production Schema.
#

##
## TODOs
##
#### Coordinate conversion.  e.g. GDA94 -> WGS84
##
#### Duplicate way detection (Duplicate node location and merging works OK)
##

##
## INCLUDES
##

use DBI;
use Math::Trig;

require '../connect/source.pl';
require '../connect/destination.pl';

require 'schema/'.$ARGV[0].'.pl';

##
## SETTINGS
##

#  # useful for debugging and tracking versions
#  $testbuild = '15';

  $empty_destination_first = 1;


  ## OSM API upload limits 

  # Maximum nodes per way
  $osmapi_way_chunk_size        =  2000;  
  
  # Maximum elements per changeset 
  $osmapi_changeset_chunk_size  = 50000;   
    # (50000 items takes ~3.2 ECU-hours on Amazon EC2 to import into API database
    # Using "/upload" REST call.)
# experimental value for the "3a" script
  $osmapi_changeset_chunk_size  = 100000000;   # Maximum elements per changeset
# Maximum elements per changeset - debugging sample
$osmapi_changeset_chunk_size  = 10000;


  ## PostgreSQL API memory limit heuristics

  # Maximum items in a generate_series(low, high)
  $pgsql_series_chunk_size      =  200;


  ## Cartographic representation of addressing
  #   (based on OpenStreetMap's shape_to_osm-Tiger.py script)
  
  # Sets the distance that the address ways should be from the main way, in metres.
  #   (Queensland surveying standards set the default parcel setback at 15 metres;
  #    we give a little less so that numbers typically appear on the road verge)
  $address_distance = 18;
## For debugging, make the offset bigger
#$address_distance = 30;

  # Sets the distance that the ends of the address ways should be pulled back from 
  # the ends of the main way, in metres.
  #   (A bit more than the address distance so that numbers do not clash 
  #    at right angle intersections)
  $address_pullback = $address_distance * 2.0;




##
## CODE
##


  sub Empty_Destination_Tables
  {
    print "\nEMPTYING THE DESTINATION DATABASE TABLES...";

    $dbh_destination->begin_work();

    $dbh_destination->do('DELETE FROM relation_tags');
    $dbh_destination->do('DELETE FROM relation_members');
    $dbh_destination->do('DELETE FROM relations');
    $dbh_destination->do('DELETE FROM way_tags');
    $dbh_destination->do('DELETE FROM way_nodes');
    $dbh_destination->do('DELETE FROM ways');
    $dbh_destination->do('DELETE FROM node_tags');
    $dbh_destination->do('DELETE FROM nodes');
    $dbh_destination->do('DELETE FROM users');
    
    $dbh_destination->commit();

    print " DONE.\n\n";
  }
  
  sub XY_From_WKB_Point
  {
    my($wkb_point) = @_;
    
    # Easiest to do this conversion on the database server
    #   (as long as it's your personal instance;
    #    if you intend to do this on a shared db
    #    maybe this function can be refactored to run locally.)
    if (!$sth_xy_from_wkb_point)
    {
      $sth_xy_from_wkb_point = 
        $dbh_origin->prepare(
          'SELECT ST_X(?), ST_Y(?)'
          ) or die "Can't prepare statement: $DBI::errstr";
    }

    my $rc = $sth_xy_from_wkb_point->execute
      (
        $wkb_point,
        $wkb_point
      ) 
      or die "Can't execute statement: $DBI::errstr";
      
    my @row = $sth_xy_from_wkb_point->fetchrow_array;
    
    if ($row[0])
    {
      my($point_x) = $row[0];
      my($point_y) = $row[1];
#      print "    Point is at $point_x, $point_y.\n";

      # sleep 2;
      
      return ($point_x, $point_y);
    }
    else
    {
      # NO-OP
      return;
    }  

  } # sub XY_From_WKB_Point

    
  sub WKB_Point_From_XY
  {
    my($point_x, $point_y) = @_;
    
    # Easiest to do this conversion on the database server
    #   (as long as it's your personal instance;
    #    if you intend to do this on a shared db
    #    maybe this function can be refactored to run locally.)
    if (!$sth_wkb_point_from_xy)
    {
      $sth_wkb_point_from_xy = 
        $dbh_origin->prepare(
          'SELECT ST_SetSRID( '.
                               'ST_Point(?, ?)'.
                               ' , 4326) as srid_point'
          ) or die "Can't prepare statement: $DBI::errstr";
    }

    my $rc = $sth_wkb_point_from_xy->execute
      (
        $point_x,
        $point_y
      ) 
      or die "Can't execute statement: $DBI::errstr";
      
    my @row = $sth_wkb_point_from_xy->fetchrow_array;
    
    if ($row[0])
    {
      my($wkb_point) = $row[0];
#      print "    WKB is $wkb_point.\n";

      # sleep 2;
      
      return ($wkb_point);
    }
    else
    {
      # NO-OP
      return;
    }  

  } # sub WKB_Point_From_XY


  sub Line_Segment_Length
  {
print "Entering Line_Segment_Length...\n";    
    my($from_x, $from_y, $to_x, $to_y) = @_;
    
#    my($length) =
#    math.sqrt((lat * lat_feet - firstpoint[0] * lat_feet)**2 + (lon * lon_feet - firstpoint[1] * lon_feet)**2) < pullback:






print "Returning from Line_Segment_Length...\n";    
  } # sub Line_Segment_Length
  
  
  # Give this an array of WKB Points (representing a Way)
  # and this will return 2 new arrays of node IDs (LHS, RHS)
  # that is cartographically offset from the old Way
  
  # TODO: PULLBACK HANDLING
  # TODO: Remove small line segments
  sub Offset_Way
  {
    my($distance, $pullback, $calc_lhs, $calc_rhs, @node_wkbs) = @_;
    my(@offset_node_ids_lhs) = ();
    my(@offset_node_ids_rhs) = ();
    
my($hashref_tags_lhs);
$hashref_tags_lhs->{'testbuild'} = $testbuild;
$hashref_tags_lhs->{'test'} = 'from-left';
my($hashref_tags_rhs);
$hashref_tags_rhs->{'testbuild'} = $testbuild;
$hashref_tags_rhs->{'test'} = 'from-right';

    
print "Entering Offset_Way...\n";
print "With ".@node_wkbs." nodes in the Way ...\n";    
    
    # The approximate number of metres in one degree of latitude
    my($metres_per_geo_degree_latitude) = 111134;

    my($metres_per_geo_degree_longitude) = undef; # calculate this later as we crawl the way
   
#    # In this version, naively calculate both offsets all the time
#    my($calc_lhs) = 1;
#    my($calc_rhs) = 1;
    
    my(@coords_lhs_x) = ();
    my(@coords_lhs_y) = ();
    my(@coords_rhs_x) = ();
    my(@coords_rhs_y) = ();
    
    my(@lengths_lhs) = ();
    my(@lengths_rhs) = ();
    
    my($length_lhs) = undef;
    my($length_rhs) = undef;
    
    my(@prev_point_lon_lat) = ();
    my($prev_delta_xp, $prev_delta_yp) = undef;
    my($first_line_segment) = 1;
    
    foreach $node_wkb (@node_wkbs)
    {
      my($node_lon, $node_lat) = XY_From_WKB_Point($node_wkb);
      
      if ($#prev_point_lon_lat >= 0)
      {
#print "  prev_point_lon_lat is ".$#prev_point_lon_lat." @prev_point_lon_lat.\n";
        # Co-located nodes?  If so, ignore and try next Node on the Way.
        next if 
          (
           ($prev_point_lon_lat[0] == $node_lon) and
           ($prev_point_lon_lat[1] == $node_lat)
          );
          
        # Calculate the approximate number of metres in one degree of longitude
        my($lat_rad) = deg2rad($node_lat);
#        my($metres_per_geo_degree_longitude) =
        $metres_per_geo_degree_longitude =
          111412.88 * cos($lat_rad)
            - 93.50 * cos(3 * $lat_rad)
             + 0.12 * cos(5 * $lat_rad);
          # Original values in feet
          # 365527.822   * math.cos(lat_rad)
          #  - 306.75853 * math.cos(3 * lat_rad)
          #    + 0.3937  * math.cos(5 * lat_rad)
      
        # Get delta between cartesian coordinates of this line segment
#print "m/lon ".($metres_per_geo_degree_longitude)."\n";
#print "dx ".($node_lon - $prev_point_lon_lat[0])."\n";
#print "dy ".($node_lat - $prev_point_lon_lat[1])."\n";
        my($delta_x) = ($node_lon - $prev_point_lon_lat[0]) * $metres_per_geo_degree_longitude;
        my($delta_y) = ($node_lat - $prev_point_lon_lat[1]) * $metres_per_geo_degree_latitude;
        
        # Get delta of the perpendicular vector of this line segment
#        my($theta) = (pi/2) - atan2($delta_y, $delta_x);
        my($theta) = atan2($delta_y, $delta_x);    # yes, this is a completely different formula to the python version
        my($delta_xp) = sin($theta) * $distance;
        my($delta_yp) = cos($theta) * $distance;
        
#        if ($delta_y > 0)
#        {
          $delta_xp = -$delta_xp;
#        }
#        else
#        {
#          $delta_yp = -$delta_yp;
#        }
        
#        print "      delta_x is $delta_x.\n";
#        print "      delta_y is $delta_y.\n";
#        print "      Theta is $theta radians.\n";
#        print "      delta_xp is $delta_xp.\n";
#        print "      delta_yp is $delta_yp.\n";

        
      
        if ($first_line_segment)
        {
          # Deal with offsets of the first node here.

$hashref_tags_lhs->{'test'} .= " theta ".rad2deg($theta);
$hashref_tags_rhs->{'test'} .= " theta ".rad2deg($theta);
          
          my($pullback_delta_x) = 0;  # TODO - pullback handling
          my($pullback_delta_y) = 0;  # TODO - pullback handling
            
          if ($calc_lhs)
          {
            my($offsetted_x) = $prev_point_lon_lat[0]
                                + ($delta_xp / $metres_per_geo_degree_longitude)
                                - $pullback_delta_x;
                                
            my($offsetted_y) = $prev_point_lon_lat[1]
                                + ($delta_yp / $metres_per_geo_degree_latitude)
                                - $pullback_delta_y;
            
#            print "      LHS offsetted_x is $offsetted_x.\n";
#            print "      LHS offsetted_y is $offsetted_y.\n";
        
            push (@coords_lhs_x, $offsetted_x);
            push (@coords_lhs_y, $offsetted_y);

#            my($offsetted_wkb) = WKB_Point_From_XY($offsetted_x, $offsetted_y);
                        
#            my($offsetted_node_id) = Node_Insert($offsetted_wkb);
            
#            print "      LHS offsetted_node_id is $offsetted_node_id.\n";

#            Node_Tags_Insert($hashref_tags_lhs, $offsetted_node_id);
            
#            push(@offset_node_ids_lhs, $offsetted_node_id);
          
          }
          if ($calc_rhs)
          {
            my($offsetted_x) = $prev_point_lon_lat[0]
                                - ($delta_xp
                                   / $metres_per_geo_degree_longitude)
                                - $pullback_delta_x;
                                
            my($offsetted_y) = $prev_point_lon_lat[1]
                                - ($delta_yp
                                   / $metres_per_geo_degree_latitude)
                                - $pullback_delta_y;
            
#            print "      RHS offsetted_x is $offsetted_x.\n";
#            print "      RHS offsetted_y is $offsetted_y.\n";

            push (@coords_rhs_x, $offsetted_x);
            push (@coords_rhs_y, $offsetted_y);
            
#            my($offsetted_wkb) = WKB_Point_From_XY($offsetted_x, $offsetted_y);                    
            
#            my($offsetted_node_id) = Node_Insert($offsetted_wkb);
            
#            print "      RHS offsetted_node_id is $offsetted_node_id.\n";

#            Node_Tags_Insert($hashref_tags_rhs, $offsetted_node_id);
            
#            push(@offset_node_ids_rhs, $offsetted_node_id);
          
          
          }

#print "Dealt with offsets of first node.\n";        
          $first_line_segment = 0;
        }
        else
        {
          # Deal with offsets of the intermediate nodes here.
$hashref_tags_lhs->{'test'} = 'intermediate-left';
$hashref_tags_rhs->{'test'} = 'intermediate-right';

          $theta  = abs( atan2($prev_delta_xp, $prev_delta_yp) );
          $theta -= abs( atan2(     $delta_xp,      $delta_yp) );
          
          my($r) = 1 + abs( tan($theta/2) );

$hashref_tags_lhs->{'test'} .= " theta ".rad2deg($theta);
$hashref_tags_rhs->{'test'} .= " theta ".rad2deg($theta);
$hashref_tags_lhs->{'test'} .= " r ".rad2deg($r);
$hashref_tags_rhs->{'test'} .= " r ".rad2deg($r);

          if ($calc_lhs)
          {
            my($offsetted_x) = $prev_point_lon_lat[0]
                                + (
                                   ($delta_xp + $prev_delta_xp)
                                   * $r
                                   / ($metres_per_geo_degree_longitude * 2)
                                  );
                                
            my($offsetted_y) = $prev_point_lon_lat[1]
                                + (
                                   ($delta_yp + $prev_delta_yp)
                                   * $r
                                   / ($metres_per_geo_degree_latitude * 2)
                                  );

#            print "      LHS offsetted_x is $offsetted_x.\n";
#            print "      LHS offsetted_y is $offsetted_y.\n";

            my($line_segment_distance) =
              sqrt(
                   ( ($offsetted_x - $coords_lhs_x[-1]) * $metres_per_geo_degree_longitude ) ** 2
                  + 
                   ( ($offsetted_y - $coords_lhs_y[-1]) * $metres_per_geo_degree_latitude ) ** 2
                   );
            $length_lhs += $line_segment_distance;       

#            print "      LHS length is $line_segment_distance, total $length_lhs.\n";
            
            push (@lengths_lhs, $line_segment_distance);

            push (@coords_lhs_x, $offsetted_x);
            push (@coords_lhs_y, $offsetted_y);

#            my($offsetted_wkb) = WKB_Point_From_XY($offsetted_x, $offsetted_y);                    
            
#            my($offsetted_node_id) = Node_Insert($offsetted_wkb);
            
#            print "      LHS offsetted_node_id is $offsetted_node_id.\n";

#            Node_Tags_Insert($hashref_tags_lhs, $offsetted_node_id);
            
#            push(@offset_node_ids_lhs, $offsetted_node_id);
          
          }
          if ($calc_rhs)
          {
            my($offsetted_x) = $prev_point_lon_lat[0]
                                - (
                                   ($delta_xp + $prev_delta_xp)
                                   * $r
                                   / ($metres_per_geo_degree_longitude * 2)
                                  );
                                
            my($offsetted_y) = $prev_point_lon_lat[1]
                                - (
                                   ($delta_yp + $prev_delta_yp)
                                   * $r
                                   / ($metres_per_geo_degree_latitude * 2)
                                  );

#            print "      RHS offsetted_x is $offsetted_x.\n";
#            print "      RHS offsetted_y is $offsetted_y.\n";

            my($line_segment_distance) =
              sqrt(
                   ( ($offsetted_x - $coords_rhs_x[-1]) * $metres_per_geo_degree_longitude ) ** 2
                  + 
                   ( ($offsetted_y - $coords_rhs_y[-1]) * $metres_per_geo_degree_latitude ) ** 2
                   );
            $length_rhs += $line_segment_distance;       

#            print "      RHS length is $line_segment_distance, total $length_rhs.\n";

            push (@lengths_rhs, $line_segment_distance);

            push (@coords_rhs_x, $offsetted_x);
            push (@coords_rhs_y, $offsetted_y);

#            my($offsetted_wkb) = WKB_Point_From_XY($offsetted_x, $offsetted_y);                    
            
#            my($offsetted_node_id) = Node_Insert($offsetted_wkb);
            
#            print "      RHS offsetted_node_id is $offsetted_node_id.\n";

#            Node_Tags_Insert($hashref_tags_rhs, $offsetted_node_id);
            
#            push(@offset_node_ids_rhs, $offsetted_node_id);
          
          
          }

        }
        
        ($prev_delta_xp, $prev_delta_yp) = ($delta_xp, $delta_yp);
      }
      
      @prev_point_lon_lat = ($node_lon, $node_lat);
    }
    
    # TODO: Deal with offsets of the final node here.
    
#print "Final Node Offset, with m/lon ".($metres_per_geo_degree_longitude)."\n";
$hashref_tags_lhs->{'test'} = 'to-left';
$hashref_tags_rhs->{'test'} = 'to-right';

    if ($calc_lhs)
    {
      my($offsetted_x) = $prev_point_lon_lat[0]
                          + ($prev_delta_xp
                             / $metres_per_geo_degree_longitude)
                          + $pullback_delta_x;
                          
      my($offsetted_y) = $prev_point_lon_lat[1]
                          + ($prev_delta_yp
                             / $metres_per_geo_degree_latitude)
                          + $pullback_delta_y;
      
#      print "      LHS offsetted_x is $offsetted_x.\n";
#      print "      LHS offsetted_y is $offsetted_y.\n";

      my($line_segment_distance) =
        sqrt(
             ( ($offsetted_x - $coords_lhs_x[-1]) * $metres_per_geo_degree_longitude ) ** 2
            + 
             ( ($offsetted_y - $coords_lhs_y[-1]) * $metres_per_geo_degree_latitude ) ** 2
             );
      $length_lhs += $line_segment_distance;       

#      print "      LHS length is $line_segment_distance, total $length_lhs.\n";

      push (@lengths_lhs, $line_segment_distance);

      push (@coords_lhs_x, $offsetted_x);
      push (@coords_lhs_y, $offsetted_y);

#      my($offsetted_wkb) = WKB_Point_From_XY($offsetted_x, $offsetted_y);                    
      
#      my($offsetted_node_id) = Node_Insert($offsetted_wkb);
      
#      print "      LHS offsetted_node_id is $offsetted_node_id.\n";

#      Node_Tags_Insert($hashref_tags_lhs, $offsetted_node_id);
      
#      push(@offset_node_ids_lhs, $offsetted_node_id);
    
    }
    if ($calc_rhs)
    {
      my($offsetted_x) = $prev_point_lon_lat[0]
                          - ($prev_delta_xp / $metres_per_geo_degree_longitude)
                          + $pullback_delta_x;
                          
      my($offsetted_y) = $prev_point_lon_lat[1]
                          - ($prev_delta_yp / $metres_per_geo_degree_latitude)
                          + $pullback_delta_y;
      
#      print "      RHS offsetted_x is $offsetted_x.\n";
#      print "      RHS offsetted_y is $offsetted_y.\n";

      my($line_segment_distance) =
        sqrt(
             ( ($offsetted_x - $coords_rhs_x[-1]) * $metres_per_geo_degree_longitude ) ** 2
            + 
             ( ($offsetted_y - $coords_rhs_y[-1]) * $metres_per_geo_degree_latitude ) ** 2
             );
      $length_rhs += $line_segment_distance;       

#      print "      RHS length is $line_segment_distance, total $length_rhs.\n";

      push (@lengths_rhs, $line_segment_distance);

      push (@coords_rhs_x, $offsetted_x);
      push (@coords_rhs_y, $offsetted_y);
            
#      my($offsetted_wkb) = WKB_Point_From_XY($offsetted_x, $offsetted_y);                    
      
#      my($offsetted_node_id) = Node_Insert($offsetted_wkb);
      
#      print "      RHS offsetted_node_id is $offsetted_node_id.\n";

#      Node_Tags_Insert($hashref_tags_rhs, $offsetted_node_id);
      
#      push(@offset_node_ids_rhs, $offsetted_node_id);
    
    
    }

    # Trim the ends off the 2 offset lines
    # Also smooth them out a bit - no less than a few metres between points
    
    if ($calc_lhs)
    {
#      print "    LHS is of length $length_lhs\n";
      @offset_node_ids_lhs = ();
      # TODO: remove all earlier assignments to @offset_node_ids_lhs in this function
      
      my($measured_length_last_node) = undef;
      
      # Is it long enough to bother building a cartographic object?
      if ($length_lhs > (3 * $address_pullback) )   # heuristic
      {
        # Apply pullback at start and end of this Way
        my($pullback_from) =               $address_pullback;
        my($pullback_to)   = $length_lhs - $address_pullback;

        my($measured_length_0) = 0;
        my($measured_length_1) = 0;
        
        foreach $i (0..$#lengths_lhs)
        {
          $measured_length_1 = $measured_length_0 + $lengths_lhs[$i];
                  
#          print "    LHS segment $i from $measured_length_0 to $measured_length_1\n";
          
          my($offsetted_wkb) = undef;                    

          if ($measured_length_0 < $pullback_from)
          {
            if ($measured_length_1 > $pullback_from)
            {
              # Apply pullback at start of Way
#              print "      LHS pullback starts at $pullback_from\n";
              
              my($invalid_proportion) =   ($pullback_from      - $measured_length_0)
                                         / ($measured_length_1  - $measured_length_0);

#              print "      LHS invalid proportion is $invalid_proportion\n";

              my($delta_x) = ($coords_lhs_x[$i+1] - $coords_lhs_x[$i]);
              my($delta_y) = ($coords_lhs_y[$i+1] - $coords_lhs_y[$i]);

              my($pulled_back_x) = $coords_lhs_x[$i]
                                    + ($invalid_proportion * $delta_x);
              my($pulled_back_y) = $coords_lhs_y[$i]
                                    + ($invalid_proportion * $delta_y);
                                       
#              print "      LHS delta       x is $delta_x\n";
#              print "      LHS delta       y is $delta_y\n";
#              print "      LHS pulled back x is $pulled_back_x\n";
#              print "      LHS pulled back y is $pulled_back_y\n";

              $offsetted_wkb = WKB_Point_From_XY($pulled_back_x, $pulled_back_y);                    
              $measured_length_last_node = $pullback_from;
            }
          }
          elsif ($measured_length_1 > $pullback_to)              
          {
            if ($measured_length_0 < $pullback_to)
            {
              # Apply pullback at end of way
#              print "      LHS pullback ends at $pullback_to\n";

              my($valid_proportion) =   ($pullback_to        - $measured_length_0)
                                       / ($measured_length_1  - $measured_length_0);

#              print "      LHS valid proportion is $valid_proportion\n";

              my($delta_x) = ($coords_lhs_x[$i+1] - $coords_lhs_x[$i]);
              my($delta_y) = ($coords_lhs_y[$i+1] - $coords_lhs_y[$i]);

              my($pulled_back_x) = $coords_lhs_x[$i]
                                    + ($valid_proportion * $delta_x);
              my($pulled_back_y) = $coords_lhs_y[$i]
                                    + ($valid_proportion * $delta_y);
                                       
#              print "      LHS delta       x is $delta_x\n";
#              print "      LHS delta       y is $delta_y\n";
#              print "      LHS pulled back x is $pulled_back_x\n";
#              print "      LHS pulled back y is $pulled_back_y\n";

              $offsetted_wkb = WKB_Point_From_XY($pulled_back_x, $pulled_back_y);                    
              $measured_length_last_node = $pullback_to;
            }
          }
          else
#          if (
#              ($measured_length_0 > $pullback_from)
#              and
#              ($measured_length_0 < $pullback_to)
#             ) 
          {
            # a coordinate not affected by pullback
            # check it for smoothness though
            if (($measured_length_0
                   - $measured_length_last_node)
                > 5)  # heuristic
#                 > 50)  # debugging - make it obvious
            {
              $offsetted_wkb = WKB_Point_From_XY($coords_lhs_x[$i], $coords_lhs_y[$i]);
              $measured_length_last_node = $measured_length_0;
            }                    
          }
          
          if ($offsetted_wkb)
          {
            # Insert point into finalised offset Way
            my($offsetted_node_id) = Node_Insert($offsetted_wkb);
            
#            print "      LHS offsetted_node_id is $offsetted_node_id.\n";

            push(@offset_node_ids_lhs, $offsetted_node_id);
          }
          
          $measured_length_0 = $measured_length_1;
        }
      }
    }
    # TODO: Consider refactoring LHS and RHS into its own function
    if ($calc_rhs)
    {
#      print "    RHS is of length $length_lhs\n";
      @offset_node_ids_rhs = ();
      # TODO: remove all earlier assignments to @offset_node_ids_rhs in this function
      
      my($measured_length_last_node) = undef;
      
      # Is it long enough to bother building a cartographic object?
      if ($length_rhs > (3 * $address_pullback) )   # heuristic
      {
        # Apply pullback at start and end of this Way
        my($pullback_from) =               $address_pullback;
        my($pullback_to)   = $length_rhs - $address_pullback;

        my($measured_length_0) = 0;
        my($measured_length_1) = 0;
        
        foreach $i (0..$#lengths_rhs)
        {
          $measured_length_1 = $measured_length_0 + $lengths_rhs[$i];
                  
#          print "    RHS segment $i from $measured_length_0 to $measured_length_1\n";
          
          my($offsetted_wkb) = undef;                    

          if ($measured_length_0 < $pullback_from)
          {
            if ($measured_length_1 > $pullback_from)
            {
              # Apply pullback at start of Way
#              print "      RHS pullback starts at $pullback_from\n";
              
              my($invalid_proportion) =   ($pullback_from      - $measured_length_0)
                                         / ($measured_length_1  - $measured_length_0);

#              print "      RHS invalid proportion is $invalid_proportion\n";

              my($delta_x) = ($coords_rhs_x[$i+1] - $coords_rhs_x[$i]);
              my($delta_y) = ($coords_rhs_y[$i+1] - $coords_rhs_y[$i]);

              my($pulled_back_x) = $coords_rhs_x[$i]
                                    + ($invalid_proportion * $delta_x);
              my($pulled_back_y) = $coords_rhs_y[$i]
                                    + ($invalid_proportion * $delta_y);
                                       
#              print "      RHS delta       x is $delta_x\n";
#              print "      RHS delta       y is $delta_y\n";
#              print "      RHS pulled back x is $pulled_back_x\n";
#              print "      RHS pulled back y is $pulled_back_y\n";

              $offsetted_wkb = WKB_Point_From_XY($pulled_back_x, $pulled_back_y);                    
              $measured_length_last_node = $pullback_from;
            }
          }
          elsif ($measured_length_1 > $pullback_to)              
          {
            if ($measured_length_0 < $pullback_to)
            {
              # Apply pullback at end of way
#              print "      RHS pullback ends at $pullback_to\n";

              my($valid_proportion) =   ($pullback_to        - $measured_length_0)
                                       / ($measured_length_1  - $measured_length_0);

#              print "      RHS valid proportion is $valid_proportion\n";

              my($delta_x) = ($coords_rhs_x[$i+1] - $coords_rhs_x[$i]);
              my($delta_y) = ($coords_rhs_y[$i+1] - $coords_rhs_y[$i]);

              my($pulled_back_x) = $coords_rhs_x[$i]
                                    + ($valid_proportion * $delta_x);
              my($pulled_back_y) = $coords_rhs_y[$i]
                                    + ($valid_proportion * $delta_y);
                                       
#              print "      RHS delta       x is $delta_x\n";
#              print "      RHS delta       y is $delta_y\n";
#              print "      RHS pulled back x is $pulled_back_x\n";
#              print "      RHS pulled back y is $pulled_back_y\n";

              $offsetted_wkb = WKB_Point_From_XY($pulled_back_x, $pulled_back_y);                    
              $measured_length_last_node = $pullback_to;
            }
          }
          else
#          if (
#              ($measured_length_0 > $pullback_from)
#              and
#              ($measured_length_0 < $pullback_to)
#             ) 
          {
            # a coordinate not affected by pullback
            # check it for smoothness though
            if (($measured_length_0
                   - $measured_length_last_node)
                > 5)  # heuristic
#                 > 50)  # debugging - make it obvious
            {
              $offsetted_wkb = WKB_Point_From_XY($coords_rhs_x[$i], $coords_rhs_y[$i]);
              $measured_length_last_node = $measured_length_0;
            }                    
          }
          
          if ($offsetted_wkb)
          {
            # Insert point into finalised offset Way
            my($offsetted_node_id) = Node_Insert($offsetted_wkb);
            
#            print "      RHS offsetted_node_id is $offsetted_node_id.\n";

            push(@offset_node_ids_rhs, $offsetted_node_id);
          }
          
          $measured_length_0 = $measured_length_1;
        }
      }
    }

    
    
print "Returning from Offset_Way...\n";    
    return (\@offset_node_ids_lhs,
             \@offset_node_ids_rhs);
  } # sub Offset_Way
  

  # give this the coordinates to insert, returns the corresponding node id
  #   for feeding into ways, tags, relations.
  sub Node_Insert
  {
    my($geom) = @_;
  
    my($node_id);

    if (!$sth_destination_node)
    {

      $sth_destination_node = 
        $dbh_destination->prepare(
          'INSERT INTO nodes '.
            '('.
             'id, '.
             'version, '.
             'user_id, '.
             'tstamp, '.
             'changeset_id, '.
             'geom'.
            ') '.
          'VALUES '.
            '(?,?,?,?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    if (!$sth_destination_node_test)
    {

      $sth_destination_node_test = 
        $dbh_destination->prepare(
          'SELECT id '.
            'FROM nodes '.
#           'WHERE geom = ?'    # Causes seq scan
           'WHERE geom && ?'    # Causes index scan
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    # Test for existing destination point and merge

    my $rc = $sth_destination_node_test->execute
      (
        $geom
      ) 
      or die "Can't execute statement: $DBI::errstr";
      
    my @row = $sth_destination_node_test->fetchrow_array;
    
    if ($row[0])
    {
      print "    Existing id for this point is ".$row[0].".\n";

      $node_id = $row[0];
      
#      sleep 2;
    }
    else
    {
      $node_id = $destination_node_lw;

      my $rc = $sth_destination_node->execute
        (
          $node_id,
          1,
          1,
          'NOW()',
          1,
          $geom
        ) 
        or die "Can't execute statement: $DBI::errstr";

      $destination_node_lw--;
      $changeset_element_count++;
    }
    
    
 
    # Test for excessive changeset element count here as well
    # to save processing very large geometries that won't fit anyway.   
    if ($changeset_element_count > $osmapi_changeset_chunk_size)
    {
      # uh oh, roll back the last transaction,
      # tell the user what to do next and wrap it up.
        
      # TODO
      $dbh_destination->rollback();
        
      print "\n\nCHANGESET LIMIT REACHED!\n\n";
        
      print 

      print "\n".
             "Destination database is now ready for use by\n".
             "  'osmosis --read-pgsql ...  --dataset-dump ...  --derive-change'.\n\n";

      print "After you have used osmosis on the destination database,\n".
             "change this script so that:\n".
             '    $start_origin_from_table = '."'".$table_name."'"."\n".
             '    $start_origin_from_row   = '.$origin_row_number."\n\n".
             "Then run this script again for the next pass.\n";
               
      exit;

    }

    
    
    
    
    print ".";
    
    return $node_id;
    
  } # sub Node_Insert



  # give this the Node IDs to insert, returns the corresponding way id
  #   for feeding into tags, relations.
  sub Way_Insert
  {
    my(@node_ids) = @_;
  
    my($way_id);
    my(@way_ids) = ();

    if (!$sth_destination_way)
    {

      $sth_destination_way = 
        $dbh_destination->prepare(
          'INSERT INTO ways '.
            '('.
             'id, '.
             'version, '.
             'user_id, '.
             'tstamp, '.
             'changeset_id '.
            ') '.
          'VALUES '.
            '(?,?,?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    if (!$sth_destination_way_nodes)
    {

      $sth_destination_way_nodes = 
        $dbh_destination->prepare(
          'INSERT INTO way_nodes '.
            '('.
             'way_id, '.
             'node_id, '.
             'sequence_id '.
            ') '.
          'VALUES '.
            '(?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    my($node_idx) = 0;
    
    while ($node_idx <= $#node_ids) 
    {
      $way_id = $destination_way_lw;
      push(@way_ids, $way_id);
      $destination_way_lw--;
      $changeset_element_count++;

      # if continuing a multi-element-relation,
      # decrement by one so that we start the next line segment
      # where we left off.
      if ($#way_ids > 0)
      {
        $node_idx--;
      }
      
      # highest node index we want to process in this chunk
      my($node_idx_max) = $node_idx + $osmapi_way_chunk_size - 1;

      my $rc = $sth_destination_way->execute
        (
          $way_id,
          1,
          1,
          'NOW()',
          1
        ) 
        or die "Can't execute statement: $DBI::errstr";
 
 
      my($node_seq) = 0;
    
      print "\nAt Way ID $way_id: Node IDs are: ".join(', ', @node_ids).".";
    
      while (
              ($node_idx <= $node_idx_max) and
              ($node_idx <= $#node_ids)
             )
      {
        my($node_id) = $node_ids[$node_idx];
        
        my $rc = $sth_destination_way_nodes->execute
        (
          $way_id,
          $node_id,
          $node_seq
        ) 
        or die "Can't execute statement: $DBI::errstr";
      
        $node_seq++;
        $node_idx++;
      }
      
    }  
      
    return @way_ids;
    
  } # sub Way_Insert


# TODO: This FUNCTION!  (TODO: Did we do this function? 
  # give this the Way IDs to insert, returns the corresponding relation id
  #   for feeding into tags.
  
  # member type = e.g.
  #         'W'        # as per osmosis\src\org\openstreetmap\osmosis\core\pgsql\v0_6\impl\MemberTypeValueMapper.java

  sub Relation_Members_Insert
  {
    my($relation_id,
       $relation_role,
       $member_type,
       @member_ids) = @_;

print "\n\n Relation_Members_Insert: @_ \n";

    if (!$sth_destination_relation)
    {

      $sth_destination_relation = 
        $dbh_destination->prepare(
          'INSERT INTO relations '.
            '('.
             'id, '.
             'version, '.
             'user_id, '.
             'tstamp, '.
             'changeset_id '.
            ') '.
          'VALUES '.
            '(?,?,?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    if (!$sth_destination_relation_ways)
    {

      $sth_destination_relation_ways = 
        $dbh_destination->prepare(
          'INSERT INTO relation_members '.
            '('.
             'relation_id, '.
             'member_id, '.
             'member_type, '.
             'member_role, '.
             'sequence_id '.
            ') '.
          'VALUES '.
            '(?,?,?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    if (!(defined($relation_id)))
    {
      $relation_id = $destination_relation_lw;

      my $rc = $sth_destination_relation->execute
        (
          $relation_id,
          1,
          1,
        'NOW()',
          1
        ) 
        or die "Can't execute statement: $DBI::errstr";

      $destination_relation_lw--;
      $changeset_element_count++;
    }
 
    my($member_seq) = 0;
    
    print "\nAt Relation ID $relation_id: Way IDs are: ".join(', ', @way_ids).".";
    
    foreach $member_id (@member_ids)
    { 
      my $rc = $sth_destination_relation_ways->execute
      (
        $relation_id,
        $member_id,
        $member_type,
        $relation_role,
        $member_seq
      ) 
      or die "Can't execute statement: $DBI::errstr";
      
      $member_seq++;
    }
      
    return $relation_id;
    
  } # sub Relation_Members_Insert



  # give this the Way IDs to insert, returns the corresponding relation id
  #   for feeding into tags.
  sub Large_Polygon_Insert
  {
    my($multipolygon_relation_id,
       $multipolygon_relation_role,
       @way_ids) = @_;
  
    if (!$sth_destination_large_polygon)
    {

      $sth_destination_large_polygon = 
        $dbh_destination->prepare(
          'INSERT INTO relations '.
            '('.
             'id, '.
             'version, '.
             'user_id, '.
             'tstamp, '.
             'changeset_id '.
            ') '.
          'VALUES '.
            '(?,?,?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    if (!$sth_destination_large_polygon_ways)
    {

      $sth_destination_large_polygon_ways = 
        $dbh_destination->prepare(
          'INSERT INTO relation_members '.
            '('.
             'relation_id, '.
             'member_id, '.
             'member_type, '.
             'member_role, '.
             'sequence_id '.
            ') '.
          'VALUES '.
            '(?,?,?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    if (!(defined($multipolygon_relation_id)))
    {
      $multipolygon_relation_id = $destination_relation_lw;

      my $rc = $sth_destination_large_polygon->execute
        (
          $multipolygon_relation_id,
          1,
          1,
        'NOW()',
          1
        ) 
        or die "Can't execute statement: $DBI::errstr";

      $destination_relation_lw--;
      $changeset_element_count++;
    }
 
    my($way_seq) = 0;
    
    print "\nAt Large Polygon Relation ID $relation_id: Way IDs are: ".join(', ', @way_ids).".";
    
    foreach $way_id (@way_ids)
    { 
      my $rc = $sth_destination_large_polygon_ways->execute
      (
        $multipolygon_relation_id,
        $way_id,
        'W',        # as per osmosis\src\org\openstreetmap\osmosis\core\pgsql\v0_6\impl\MemberTypeValueMapper.java
        $multipolygon_relation_role,
        $way_seq
      ) 
      or die "Can't execute statement: $DBI::errstr";
      
      $way_seq++;
    }
      
    return $multipolygon_relation_id;
    
  } # sub Large_Polygon_Insert


  sub Node_Tag_Prepare_Merge
  {
    my($node_id, $k, $v) = @_;
  
    if (!$sth_destination_node_tag_test)
    {

      $sth_destination_node_tag_test = 
        $dbh_destination->prepare(
          'SELECT v '.
            'FROM node_tags '.
           'WHERE node_id = ? '. 
             'AND k = ?'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    if (!$sth_destination_node_tag_delete)
    {

      $sth_destination_node_tag_delete = 
        $dbh_destination->prepare(
          'DELETE '.
            'FROM node_tags '.
           'WHERE node_id = ? '. 
             'AND k = ?'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    my $rc = $sth_destination_node_tag_test->execute
      (
        $node_id,
        $k
      ) 
      or die "Can't execute statement: $DBI::errstr";
      
    my @row = $sth_destination_node_tag_test->fetchrow_array;
    
    if ($row[0])
    {
      print "    Existing value for node $node_id key $k is ".$row[0].".\n";

#      sleep 2;
      
      # If existing and new values are different, merge them
      if ($v ne $row[0])
      {
        $v .= ';'.$row[0];
      }  
      
      # Delete the row.  The merged value will be added back in later.
      my $rc = $sth_destination_node_tag_delete->execute
        (
          $node_id,
          $k
        ) 
        or die "Can't execute statement: $DBI::errstr";
      
    }
      
    return $v;
  }


  sub Node_Tags_Insert
  {
    my($tags, $node_id) = @_;
  
    if (!$sth_destination_node_tag)
    {

      $sth_destination_node_tag = 
        $dbh_destination->prepare(
          'INSERT INTO node_tags '.
            '('.
             'node_id, '.
             'k, '.
             'v'.
            ') '.
          'VALUES '.
            '(?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     


    # We're not too worried about duplicate tags (except perhaps for bloat
    # in the osmosis simple schema database)
    # We assume they will get detected/merged by osmosis in the transformation
    # to the final osm api schema.
    

    # Apply any attribute tattoos
    foreach $tag_key (keys %attributes_tattoo)
    {
    
      my ($v) = Node_Tag_Prepare_Merge(
                  $node_id,
                  $tag_key,
                  $attributes_tattoo{$tag_key}
                );  

      my $rc = $sth_destination_node_tag->execute
        (
          $node_id,
          $tag_key,
          $v
        ) 
        or die "Can't execute statement: $DBI::errstr";
    
    }


    # Add tags to the node according to the translation mapping between
    # the attribute names in the origin database and the key names we want
    # in the cm/osm db
    
    foreach $attribute_name (keys %{$tags})
    {
    
      my($v0) = undef;
    
      # Test for simple substitution of the attribute name
      if (
           ( exists $attributes_origin{$attribute_name} ) and
           ( $tags->{$attribute_name} )
         )
      {
        $v0 = $tags->{$attribute_name};
        $attribute_name = $attributes_origin{$attribute_name};

#        my ($v) = 
#                   Node_Tag_Prepare_Merge(
#                    $node_id,
#                    $attributes_origin{$attribute_name},
#                    $tags->{$attribute_name}
#                  );  

#        my $rc = $sth_destination_node_tag->execute
#          (
#            $node_id,
#            $attributes_origin{$attribute_name},
#            $v
#          ) 
#          or die "Can't execute statement: $DBI::errstr";
      }
      
      # Test for attribute values
      #   - give it the chance to override the origin attributes
      if (
            ( exists $attribute_translate{$attribute_name} ) and
#            ( exists $attribute_translate{$attribute_name}{$tags->{$attribute_name}} )
            ( exists $attribute_translate{$attribute_name}{$v0} )
         )
      {
        foreach $tag_key ( keys (%{ $attribute_translate{$attribute_name}{$tags->{$attribute_name}} }) )
        {
#          print "WANT TO ADD: ".$tag_key." = ".
#                 $attribute_translate{$attribute_name}{$tags->{$attribute_name}}{$tag_key}.
#                 ".\n";
#          sleep 1;
          
          my ($v) = Node_Tag_Prepare_Merge(
                      $node_id,
                      $tag_key,
                      $attribute_translate{$attribute_name}{$tags->{$attribute_name}}{$tag_key}
                    );  



          my $rc = $sth_destination_node_tag->execute
            (
              $node_id,
              $tag_key,
              $v
            ) 
            or die "Can't execute statement: $DBI::errstr";
        }
      }
      elsif (defined $v0)
      {
        my ($v) = 
                   Node_Tag_Prepare_Merge(
                    $node_id,
                    $attribute_name,
                    $v0
                  );  

        my $rc = $sth_destination_node_tag->execute
          (
            $node_id,
            $attribute_name,
            $v
          ) 
          or die "Can't execute statement: $DBI::errstr";
      
      }  
    }
    
  } # sub Node_Tags_Insert


  # Very similar to Node_Tags_Insert, except for ways
  sub Way_Tags_Insert
  {
    my($tags, $way_id) = @_;
  
    if (!$sth_destination_way_tag)
    {

      $sth_destination_way_tag = 
        $dbh_destination->prepare(
          'INSERT INTO way_tags '.
            '('.
             'way_id, '.
             'k, '.
             'v'.
            ') '.
          'VALUES '.
            '(?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    # We're not too worried about duplicate tags (except perhaps for bloat
    # in the osmosis simple scheme database)
    # We assume they will get detected/merged by osmosis in the transformation
    # to the final osm api schema.
    
    
    # Apply any attribute tattoos
    foreach $tag_key (keys %attributes_tattoo)
    {
    
      my $rc = $sth_destination_way_tag->execute
        (
          $way_id,
          $tag_key,
          $attributes_tattoo{$tag_key}
        ) 
        or die "Can't execute statement: $DBI::errstr";
    
    }
    
    
    # Add tags to the node according to the translation mapping between
    # the attribute names in the origin database and the key names we want
    # in the cm/osm db
    
    foreach $attribute_name (keys %{$tags})
    {
    
      my($v0) = undef;
    
      # Test for simple substitution of the attribute name
      if (
           ( exists $attributes_origin{$attribute_name} ) and
           ( $tags->{$attribute_name} )
         )
      {
        $v0 = $tags->{$attribute_name};
        $attribute_name = $attributes_origin{$attribute_name};
#          print "A: WANT TO ADD: ".$attribute_name." = ".
#                 $v0.
#                 ".\n";
#          sleep 1;

#        my $rc = $sth_destination_way_tag->execute
#          (
#            $way_id,
#            $attributes_origin{$attribute_name},
#            $tags->{$attribute_name}
#          ) 
#          or die "Can't execute statement: $DBI::errstr";
      }
      
      # Test for attribute values
      #   - give it the chance to override the origin attributes
      if (
            ( exists $attribute_translate{$attribute_name} ) and
#            ( exists $attribute_translate{$attribute_name}{$tags->{$attribute_name}} )
            ( exists $attribute_translate{$attribute_name}{$v0} )   
         )
      {
        foreach $tag_key ( keys (%{ $attribute_translate{$attribute_name}{$tags->{$attribute_name}} }) )
        {
#          print "B: WANT TO ADD: ".$tag_key." = ".
#                 $attribute_translate{$attribute_name}{$tags->{$attribute_name}}{$tag_key}.
#                 ".\n";
#          sleep 1;
          
          my $rc = $sth_destination_way_tag->execute
            (
              $way_id,
              $tag_key,
              $attribute_translate{$attribute_name}{$tags->{$attribute_name}}{$tag_key}
            ) 
            or die "Can't execute statement: $DBI::errstr";
        }
      }  
      elsif (defined $v0)
      {
#          print "C. WANT TO ADD: ".$attribute_name." = ".
#                 $v0.
#                 ".\n";
#          sleep 1;
        my $rc = $sth_destination_way_tag->execute
          (
            $way_id,
            $attribute_name,
            $v0
          ) 
          or die "Can't execute statement: $DBI::errstr";
      
      }  
    }
      
    
  } # sub Way_Tags_Insert


  # Very similar to Node_Tags_Insert, except for large polygons
  sub Large_Polygon_Tags_Insert
  {
    my($tags, $relation_id) = @_;
    
    # Special case for large polygons - mark the relation as such.
    $tags->{'type'} = 'multipolygon';
    
    return Relation_Tags_Insert($tags, $relation_id);
  } # sub Large_Polygon_Tags_Insert

  
  
  # Very similar to Node_Tags_Insert, except for large polygons
  sub Relation_Tags_Insert
  {
    my($tags, $relation_id) = @_;
  
    if (!$sth_destination_relation_tag)
    {

      $sth_destination_relation_tag = 
        $dbh_destination->prepare(
          'INSERT INTO relation_tags '.
            '('.
             'relation_id, '.
             'k, '.
             'v'.
            ') '.
          'VALUES '.
            '(?,?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     


    # We're not too worried about duplicate tags (except perhaps for bloat
    # in the osmosis simple scheme database)
    # We assume they will get detected/merged by osmosis in the transformation
    # to the final osm api schema.
    
    
    # Add tags to the node according to the translation mapping between
    # the attribute names in the origin database and the key names we want
    # in the cm/osm db
    
    foreach $attribute_name (keys %{$tags})
    {
    
      my($v0) = undef;
    
      # Test for simple substitution of the attribute name
      if (
           ( exists $attributes_origin{$attribute_name} ) and
           ( $tags->{$attribute_name} )
         )
      {
        $v0 = $tags->{$attribute_name};
        $attribute_name = $attributes_origin{$attribute_name};

#        my $rc = $sth_destination_relation_tag->execute
#          (
#            $relation_id,
#            $attributes_origin{$attribute_name},
#            $tags->{$attribute_name}
#          ) 
#          or die "Can't execute statement: $DBI::errstr";
      }
      
      # Test for attribute values
      if (
            ( exists $attribute_translate{$attribute_name} ) and
#            ( exists $attribute_translate{$attribute_name}{$tags->{$attribute_name}} )
            ( exists $attribute_translate{$attribute_name}{$v0} )   
         )
      {
        foreach $tag_key ( keys (%{ $attribute_translate{$attribute_name}{$tags->{$attribute_name}} }) )
        {
          print "WANT TO ADD: ".$tag_key." = ".
                 $attribute_translate{$attribute_name}{$tags->{$attribute_name}}{$tag_key}.
                 ".\n";
          sleep 1;
          
          my $rc = $sth_destination_relation_tag->execute
            (
              $relation_id,
              $tag_key,
              $attribute_translate{$attribute_name}{$tags->{$attribute_name}}{$tag_key}
            ) 
            or die "Can't execute statement: $DBI::errstr";
        }
      }  
      elsif (defined $v0)
      {
        my $rc = $sth_destination_relation_tag->execute
          (
            $relation_id,
            $attribute_name,
            $v0
          ) 
          or die "Can't execute statement: $DBI::errstr";
      
      }  
    }
      
    
  } # sub Relation_Tags_Insert



  # Stub to insert a token user into the destination database.
  sub User_Insert
  {
    if (!$sth_destination_user)
    {

      $sth_destination_user = 
        $dbh_destination->prepare(
          'INSERT INTO users '.
            '('.
             'id, '.
             'name'.
            ') '.
          'VALUES '.
            '(?,?)'
        ) or die "Can't prepare statement: $DBI::errstr";
    }     

    $dbh_destination->begin_work();

    my $rc = $sth_destination_user->execute
      (
        1,
        $commonmap_user_name
      ) 
      or die "Can't execute statement: $DBI::errstr";

    $dbh_destination->commit();

    
  } # sub User_Insert


  # Helper function to add the nodes to a Way.  Also handles the > 2000 node cases.
  # For $type,
  #   Way: "W"    (LineString)
  #   Area: "A"   (Polygon)
  # For $multipolygon_relation_id,
  #   if defined, ways will be added to the relation id with role $multipolygon_relation_role.
  # Returns the multipolygon relation ID and the way IDs.

  sub Way_and_Tags_Insert
  {
    my( $type, 
        $multipolygon_relation_id,
        $multipolygon_relation_role,
        $tags, 
        @node_ids ) = @_;

    # Do a fixup for cliffs, embankments, etc,
    # GA have them encoded in one direction and the OSM
    # renderers expect the high and low sides to be on the
    # opposite side of the discontinuity line.
#print "Tags are: ".(join(' ',keys %{$tags}))."\n";
#print "Feattype is: ".($tags->{'feattype'})."\n";
    if (
         ( $tags->{'feattype'} eq 'Cliff' ) or
         ( $tags->{'feattype'} eq 'Embankment' ) or
         ( $tags->{'feattype'} eq 'Road Causeway' ) 
       ) 
    {
#      print "\nNode IDs were: ".join(', ', @node_ids).".";
      @node_ids = reverse(@node_ids);
#      print "\nNode IDs are now: ".join(', ', @node_ids).".";
    }
    # End of fixup
    
    
    my(@way_ids) = Way_Insert( @node_ids );
    
    if ($type eq 'W')
    {
      # We've split the way up into 2000-node slices, just add the tags
      # onto each slice.
      foreach $way_id (@way_ids)
      {
        Way_Tags_Insert( $tags, $way_id );
      }
    }
    
    if ($type eq 'A')
    {
      if (
          ($#way_ids > 0) or
          ($multipolygon_relation_role)
         )
      {
        # We've split the an area up into 2000-node slices, we need to
        # add the tags onto a parent "multipolygon" relation.
        # and then attach each slice to that relation.
        
        # Or, this area has an outer and inner boundary
        # and must participate in a multipolygon relation
        
        my($had_multipolygon_relation_id) = $multipolygon_relation_id;
        
        if (!($multipolygon_relation_role))
        {
          $multipolygon_relation_role = 'outer';
        }
      
        $multipolygon_relation_id = Large_Polygon_Insert($multipolygon_relation_id,
                                                         $multipolygon_relation_role,
                                                         @way_ids);

        if (!($had_multipolygon_relation_id))
        {
          # Only insert these tags once per multipolygon ID.
          Large_Polygon_Tags_Insert( $tags, $multipolygon_relation_id );
        }  
      }
      else
      {
        # Area did not have over 2000 nodes,
        # Insert in simplified form
                
        Way_Tags_Insert( $tags, $way_ids[0] );
      }  

    }
    
    return ($multipolygon_relation_id, @way_ids);
    
  } # sub Way_and_Tags_Insert





##
## MAIN CODE
##

  # Global variables
  $destination_node_lw = -1;
  $destination_way_lw = -1;
  $destination_relation_lw = -1;
  
  $changeset_element_count = 0;
  
  $| = 1;    # "Make sure pipes are piping hot." - helps show the dot-progression in real time.

  # Connect to databases

  $dbh_origin = DBI->connect($conn_origin, $user_origin, $password_origin, 
    {
      RaiseError => 1, 
      AutoCommit => 0,
      ChopBlanks => 1
    })
        or die "Can't connect to $conn_origin: $DBI::errstr";

  $dbh_destination = DBI->connect($conn_destination, $user_destination, $password_destination, 
    {
      RaiseError => 1, 
      AutoCommit => 1
    })
        or die "Can't connect to $dbh_destination: $DBI::errstr";

  if ($empty_destination_first)
  {
    Empty_Destination_Tables;
#    exit;
  }


  # Start the population process.
  
  User_Insert;
  

  # Start going through each source table in turn

  foreach $table_name (@tables_origin)
  {
    print "Processing origin table $table_name\n";
    
    # see if we need to skip forward to a particular table name
    if ($start_origin_from_table)
    {
      if ($start_origin_from_table ne $table_name)
      {
        # try next table name
        next;
      }
      else
      {
        # found our table, don't need to keep track any more.
        $start_origin_from_table = undef;
      }
    }
    else
    {
      # we might have started this script from an earlier 
      # $start_origin_from_table but we don't need to
      # know the alternative start row now.
      $start_origin_from_row = 0;
    }
    
    my $sth_origin = 
      $dbh_origin->prepare(
        'SELECT *, '.
               'GeometryType(wkb_geometry) as type_geometry, '.
               'NumGeometries(wkb_geometry) as num_geometries, '.
               'NumInteriorRings(wkb_geometry) as num_intrings, '.
               'NumPoints(wkb_geometry) as numpoints_geometry, '.
               'Case '.
                 "When GeometryType(wkb_geometry)='POLYGON' Then NumPoints(ExteriorRing(wkb_geometry)) ".
                 'Else 0'.
               'End '.
               'as numpoints_extring, '.     ##### TODO: Do not test for this if not a polygon
#               'CASE WHEN '.
#                 "GeometryType(wkb_geometry) = 'POLYGON' ".
#                 'THEN ExteriorRing(wkb_geometry) '.
#                 'ELSE NULL '.
#                 'END '.  
#                 ' as wkb_extring_geometry, '.
##               'CASE WHEN '.
##                 "GeometryType(wkb_geometry) = 'POLYGON' ".
##                 'THEN AsText(ExteriorRing(wkb_geometry)) '.
##                 'ELSE NULL '.
##                 'END '.  
##                 ' as wkt_extring_geometry, '.
##               'AsText(wkb_geometry) as wkt_geometry, '.
###               'Transform(SetSRID(wkb_geometry, 4283), 4326) as srid_geometry '.  ####################### Assume GDA94 -> WGS84
               'SetSRID(wkb_geometry, 4326) as srid_geometry '.  ####################### Assume GDA94 -> WGS84
        'FROM '.$table_name.' '.
        'ORDER BY ogc_fid '.  # provide deterministic offsetting between executions of this query
        'LIMIT '.$osmapi_changeset_chunk_size.' '.  # will never need more than this at a time.
        'OFFSET '.$start_origin_from_row
        ) or die "Can't prepare statement: $DBI::errstr";

    my $rc = $sth_origin->execute
      or die "Can't execute statement: $DBI::errstr";

    print "Query start at row $start_origin_from_row.\n";
    print "Query will return $sth_origin->{NUM_OF_FIELDS} fields.\n";
    print "Field names: @{ $sth_origin->{NAME} }\n\n";

#    my($origin_row_number) = $start_origin_from_row;
    $origin_row_number = $start_origin_from_row;
    
    while (my $hashref = $sth_origin->fetchrow_hashref)
    {
#      # Print out row contents for debugging purposes
#      foreach $column_name (sort keys %{$hashref})
#      {
#        my($column_value) = $hashref->{$column_name};
#        
#        print "  Column name: '$column_name'\n";
#        print "    Column value: '$column_value'\n";
#        
#      }

      print "\nRead id ".$hashref->{'ogc_fid'}." from source.\n";
      print "Geometry type ".$hashref->{'type_geometry'}.
                     " with ".$hashref->{'numpoints_geometry'}." points in linestring".
                     " or ".$hashref->{'numpoints_extring'}." points in exterior ring.\n";
      

#      ##### TODO: This is a hack - need to handle large polygons without the pgsql server running out of memory
#      if ($hashref->{'numpoints_extring'} > $osmapi_way_chunk_size)
#      {
#        print "\n\nWARNING - TOO MANY NODES, SKIPPING.\n\n";
#        next;
#      }
        
      
      $dbh_destination->begin_work();
      
      # Extract points of linestring
      if ($hashref->{'type_geometry'} eq 'LINESTRING')
      {
      
        ############ TODO: OPTIMISE THIS PREPARED STATEMENT
        if (!$sth_origin_linestring_points{$table_name})
        {
          $sth_origin_linestring_points{$table_name} = 
            $dbh_origin->prepare(
              'SELECT '.
                    'SetSRID(PointN(wkb_geometry, '.
                                   'generate_series(1, NPoints(wkb_geometry))), 4326) as srid_point '.
              'FROM '.
                     '(SELECT '.$affine.' as wkb_geometry '.
                       'FROM '.$table_name.' '.
                      'WHERE ogc_fid = ?'.
                     ') as source'
              ) or die "Can't prepare statement: $DBI::errstr";
        }      
            
        my $rc = $sth_origin_linestring_points{$table_name}->execute( $hashref->{'ogc_fid'} ) 
          or die "Can't execute statement: $DBI::errstr";

#        print "LineString Query will return $sth_origin_linestring_points{$table_name}->{NUM_OF_FIELDS} fields.\n";
#        print "Field names: @{ $sth_origin_linestring_points{$table_name}->{NAME} }\n\n";


        my(@node_ids) = ();
        my(@node_wkbs) = ();

        while (my $hashref_points = $sth_origin_linestring_points{$table_name}->fetchrow_hashref)
        {
          # Print out row contents for debugging purposes
          foreach $column_name (sort keys %{$hashref_points})
          {
            my($column_value) = $hashref_points->{$column_name};
          
#            print "  Column name: '$column_name'\n";
#            print "    Column value: '$column_value'\n";
        
        
          }
          
          my($node_id) = Node_Insert( $hashref_points->{'srid_point'} );
          
          push(@node_ids,  $node_id);
          push(@node_wkbs, $hashref_points->{'srid_point'} );
        }  

        # Create some offset lines for cartographic representation
        #  of house numbers
        
        # First get the street number endpoints
        my($from_left)  = $hashref->{ $street_number_attributes[0] };
        my($from_right) = $hashref->{ $street_number_attributes[1] };
        my($to_left)    = $hashref->{ $street_number_attributes[2] };
        my($to_right)   = $hashref->{ $street_number_attributes[3] };
 
#        print "    From Left  = $from_left\n";
#        print "    From Right = $from_right\n";
#        print "    To Left    = $to_left\n";
#        print "    To right   = $to_right\n";
        
        my($calc_lhs) = ($from_left != $street_number_nil_value)
                         or
                         ($to_left != $street_number_nil_value);

        my($calc_rhs) = ($from_right != $street_number_nil_value)
                         or
                         ($to_right != $street_number_nil_value);

        # Then get the interpolation cartographic lines.
        # TODO: Indicate if these are needed, sometimes street numbers are "-1"
        my ($offset_left_node_ids,
            $offset_right_node_ids)
            = Offset_Way($address_distance,
                         $address_pullback,
                         $calc_lhs,
                         $calc_rhs,
                         @node_wkbs);

        # (We need to make sure that we have acquired all the Node IDs
        #  we need at this point, in order to insert the way and its
        #  associated address interpolation all at once)

        # Then store those lines and
        # the endpoints, if we have interpolation lines to store them on.
        my($hashref_tags_addr_endpoint);
        my($addr_relation_id) = undef;
        
        if ($#{$offset_left_node_ids} > 0)
        {
#          if (
#              ($from_left != $street_number_nil_value)
#              or
#              ($to_left != $street_number_nil_value)
#             ) 
#          {

            my($hashref_tags_addr_interpolate);
            # odd or even?
            if (
                ($from_left % 2 == 0)
                and
                ($to_left % 2 == 0)
               )
            {
              $hashref_tags_addr_interpolate->{'addr:interpolation'} = 'even';
            }
            elsif (
                   ($from_left % 2 == 1)
                   and
                   ($to_left % 2 == 1)
                  )
            {
              $hashref_tags_addr_interpolate->{'addr:interpolation'} = 'odd';
            }
            else
            {
              $hashref_tags_addr_interpolate->{'addr:interpolation'} = 'unknown';
            }    
            
            $hashref_tags_addr_interpolate->{'addr:street'} =
               $hashref_tags_addr_endpoint->{'addr:street'} =
                   $hashref->{$street_number_attributes[4]};
            
            my($house_relation_id, @house_way_ids) =
              Way_and_Tags_Insert('W', undef, undef, 
                                 $hashref_tags_addr_interpolate, 
                                 @{ $offset_left_node_ids  });
                               
#  print "\n\n\nWANT TO INSERT FROMLEFT $from_left AT NODE ".($offset_left_node_ids->[0])." !!!\n";
            $hashref_tags_addr_endpoint->{'addr:housenumber'} = $from_left;
            Node_Tags_Insert($hashref_tags_addr_endpoint, $offset_left_node_ids->[0]);
          
#  print "\nWANT TO INSERT TOLEFT $to_left AT NODE ".($offset_left_node_ids->[-1])." !!!\n";
            $hashref_tags_addr_endpoint->{'addr:housenumber'} = $to_left;
            Node_Tags_Insert($hashref_tags_addr_endpoint, $offset_left_node_ids->[-1]);
            
            if ($house_relation_id)
            {
              $addr_relation_id = 
                Relation_Members_Insert($addr_relation_id,
                                        'house',
                                        'R',
                                        $house_relation_id);
            }
            else
            {
              $addr_relation_id = 
                Relation_Members_Insert($addr_relation_id,
                                        'house',
                                        'W',
                                        @house_way_ids);
            }                                
#          }
        }
        
        if ($#{$offset_right_node_ids} > 0)
        {
#          if (
#              ($from_right != $street_number_nil_value)
#              or
#              ($to_right != $street_number_nil_value)
#             ) 
#          {

            my($hashref_tags_addr_interpolate);
            # odd or even?
            if (
                ($from_right % 2 == 0)
                and
                ($to_right % 2 == 0)
               )
            {
              $hashref_tags_addr_interpolate->{'addr:interpolation'} = 'even';
            }
            elsif (
                   ($from_right % 2 == 1)
                   and
                   ($to_right % 2 == 1)
                  )
            {
              $hashref_tags_addr_interpolate->{'addr:interpolation'} = 'odd';
            }
            else
            {
              $hashref_tags_addr_interpolate->{'addr:interpolation'} = 'unknown';
            }    
            
            $hashref_tags_addr_interpolate->{'addr:street'} =
               $hashref_tags_addr_endpoint->{'addr:street'} =
                   $hashref->{$street_number_attributes[5]};

            my($house_relation_id, @house_way_ids) =
              Way_and_Tags_Insert('W', undef, undef, 
                                 $hashref_tags_addr_interpolate, 
                                 @{ $offset_right_node_ids });

#  print "\nWANT TO INSERT FROMRIGHT $from_right AT NODE ".($offset_right_node_ids->[0])." !!!\n";
            $hashref_tags_addr_endpoint->{'addr:housenumber'} = $from_right;
            Node_Tags_Insert($hashref_tags_addr_endpoint, $offset_right_node_ids->[0]);
          
#  print "\nWANT TO INSERT TORIGHT $to_right AT NODE ".($offset_right_node_ids->[-1])." !!!\n";
            $hashref_tags_addr_endpoint->{'addr:housenumber'} = $to_right;
            Node_Tags_Insert($hashref_tags_addr_endpoint, $offset_right_node_ids->[-1]);
            
            if ($house_relation_id)
            {
              $addr_relation_id = 
                Relation_Members_Insert($addr_relation_id,
                                        'house',
                                        'R',
                                        $house_relation_id);
            }
            else
            {
              $addr_relation_id = 
                Relation_Members_Insert($addr_relation_id,
                                        'house',
                                        'W',
                                        @house_way_ids);
            }                                
#          }
        }


        # Insert the Way itself.
        my($street_relation_id, @street_way_ids) =
#        my($way_id) = Way_Insert( @node_ids );
#        Way_Tags_Insert( $hashref, $way_id );
          Way_and_Tags_Insert('W', undef, undef, $hashref, @node_ids);
          
        # Transfer name of street to the name of the relation
        my($hashref_tags_addr_relation);
        $hashref_tags_addr_relation->{'name'} = $hashref->{$street_number_attributes[4]};
        if (
            $hashref->{$street_number_attributes[4]} ne
            $hashref->{$street_number_attributes[5]}
            )
        {    
          $hashref_tags_addr_relation->{'name'} .= ';'.$hashref->{$street_number_attributes[5]};
        }
        
                             
        # reference the street from the interpolation relation
        if ($street_relation_id)
        {
          $addr_relation_id = 
            Relation_Members_Insert($addr_relation_id,
                                    'street',
                                    'R',
                                    $street_relation_id);
        }
        else
        {
          $addr_relation_id = 
            Relation_Members_Insert($addr_relation_id,
                                    'street',
                                    'W',
                                    @street_way_ids);
        }                                
 
#print "\n\n\n\n '".join(',', keys (%{ $hashref }))."' \n\n\n\n";
print "\n   Inserting '".$hashref_tags_addr_relation->{'name'}."' ";
print "into address relation '".$addr_relation_id."' \n";
        Relation_Tags_Insert($hashref_tags_addr_relation,
                             $addr_relation_id);

      } # if ($hashref->{'type_geometry'} eq 'LINESTRING')



      # Extract points of multilinestring
      if ($hashref->{'type_geometry'} eq 'MULTILINESTRING')
      {
        # Yes, sometimes you will get multilinestrings in GA data
        # that has been split into mapsheet tiles.
        # This is because there are linestrings that "spill over"
        # the mapsheet boundary and then come back into the boundary
        # later down the way.  GA will make these multilinestrings
        # and the missing portion will show up in the adjoining mapsheet.
        # 
        # This import script will split up the multilinestring
        # into separate ways and copy the tags across.
      
        ############ TODO: OPTIMISE THIS PREPARED STATEMENT
        if (!$sth_origin_multilinestring_points{$table_name})
        {
          $sth_origin_multilinestring_points{$table_name} = 
            $dbh_origin->prepare(
              'SELECT '.
                    'SetSRID(PointN(wkb_sub_geometry, '.
                                   'generate_series(1, '.
                                     'NPoints(wkb_sub_geometry))),'.
                                     ' 4326) as srid_point '.
              'FROM '.
                     '(SELECT GeometryN('.$affine.', ?) as wkb_sub_geometry '.
                       'FROM '.$table_name.' '.
                      'WHERE ogc_fid = ?'.
                     ') as source'
              ) or die "Can't prepare statement: $DBI::errstr";
        }      
        
        # Loop through the linestrings in the multilinestring
        foreach $geom_index (1..$hashref->{'num_geometries'})
        {
          my $rc = $sth_origin_multilinestring_points{$table_name}->execute( $geom_index,
                                                                             $hashref->{'ogc_fid'} ) 
            or die "Can't execute statement: $DBI::errstr";

#          print "MultiLineString Query will return ".
#                 "$sth_origin_linestring_points{$table_name}->{NUM_OF_FIELDS} fields.\n";
#          print "Field names: @{ $sth_origin_linestring_points{$table_name}->{NAME} }\n\n";
          print "MultiLineString Sub-geometry index: $geom_index\n\n";


          my(@node_ids) = ();

          while (my $hashref_points = $sth_origin_multilinestring_points{$table_name}->fetchrow_hashref)
          {
            # Print out row contents for debugging purposes
            foreach $column_name (sort keys %{$hashref_points})
            {
              my($column_value) = $hashref_points->{$column_name};
          
#              print "  Column name: '$column_name'\n";
#              print "    Column value: '$column_value'\n";
        
        
            }
          
            my($node_id) = Node_Insert( $hashref_points->{'srid_point'} );
          
            push(@node_ids, $node_id);
          }  

          Way_and_Tags_Insert('W', undef, undef, $hashref, @node_ids);
        
        } # for each sub-geometry
 
      } # if ($hashref->{'type_geometry'} eq 'MULTILINESTRING')


      # Extract points of polygon
      my($multipolygon_relation_id);
#      my(@way_ids_outer_ring) = ();
      if ($hashref->{'type_geometry'} eq 'POLYGON')
      {
      
        
        ############ TODO: OPTIMISE THIS PREPARED STATEMENT
        if (!$sth_origin_polygon_points{$table_name})
        {
          $sth_origin_polygon_points{$table_name} = 
            $dbh_origin->prepare(
              'SELECT '.
                    'SetSRID(PointN(wkb_extring_geometry, '.
#                                   'generate_series(1, NPoints(wkb_extring_geometry))), 4326) as srid_point '.
#                                   'generate_series(1, 3)), 4326) as srid_point '.
                                   'generate_series(?::int, ?::int)), 4326) as srid_point '.
              'FROM '.
                     '(SELECT ExteriorRing('.$affine.') as wkb_extring_geometry '.
                       'FROM '.$table_name.' '.
                      'WHERE ogc_fid = ?'.
                     ') as source'
              ) or die "Can't prepare statement: $DBI::errstr";
        }      
        
        # We use a windowed approach to selecting individual points from the polygon
        # as otherwise very detailed polygons cause generate_series to exhaust
        # memory on the postgres server.
        my($lower_bound) = 1;
        my($upper_bound) = $pgsql_series_chunk_size;
        my(@node_ids) = ();

        while ($lower_bound <= $hashref->{'numpoints_extring'})
        {
          # trim the upper bound to the actual number of points if necessary
          if ($hashref->{'numpoints_extring'} < $upper_bound)
          {
            $upper_bound = $hashref->{'numpoints_extring'};
          }

          print "\nPolygon point windowed query from position '$lower_bound' to position '$upper_bound'...\n";

          my $rc = $sth_origin_polygon_points{$table_name}->execute( 
                                                                     $lower_bound,
                                                                     $upper_bound,
                                                                     $hashref->{'ogc_fid'} )
            or die "Can't execute statement: $DBI::errstr";

#          print "Polygon Query will return $sth_origin_polygon_points{$table_name}->{NUM_OF_FIELDS} fields.\n";
#          print "Field names: @{ $sth_origin_polygon_points{$table_name}->{NAME} }\n\n";


          while (my $hashref_points = $sth_origin_polygon_points{$table_name}->fetchrow_hashref)
          {
            # Print out row contents for debugging purposes
            foreach $column_name (sort keys %{$hashref_points})
            {
              my($column_value) = $hashref_points->{$column_name};
          
#              print "  Column name: '$column_name'\n";
#              print "    Column value: '$column_value'\n";
        
        
            }
          
            my($node_id) = Node_Insert( $hashref_points->{'srid_point'} );
          
            push(@node_ids, $node_id);
          } 
          
          # adjust window for next pass
          $lower_bound = ($upper_bound + 1);
          $upper_bound += $pgsql_series_chunk_size;
          
        }

#        my($way_id) = Way_Insert( @node_ids );
#        Way_Tags_Insert( $hashref, $way_id );

        if ($hashref->{'num_intrings'} > 0)
        {
          # Force as the outer ring of a multipolygon
          $multipolygon_relation_id = 
            Way_and_Tags_Insert('A', undef, 'outer', $hashref, @node_ids);
        }
        else
        {
          # Try and insert this as a simple closed way
          # (which will work if <= 2000 nodes)
          $multipolygon_relation_id = 
            Way_and_Tags_Insert('A', undef, undef, $hashref, @node_ids);
        }    
 
      } # if ($hashref->{'type_geometry'} eq 'POLYGON')


      # Extract points of polygon interior rings
#      my(@way_ids_inner_rings) = ();
      if ($hashref->{'type_geometry'} eq 'POLYGON')
      {
      
   
        ############ TODO: OPTIMISE THIS PREPARED STATEMENT
        if (!$sth_origin_polygon_intring_points{$table_name})
        {
          $sth_origin_polygon_intring_points{$table_name} = 
            $dbh_origin->prepare(
              'SELECT '.
                    'SetSRID(PointN(wkb_intring_geometry, '.
#                                   'generate_series(1, '.
#                                     'NPoints(wkb_intring_geometry))),'.
                                   'generate_series(?::int, ?::int)), 4326) as srid_point '.
              'FROM '.
                     '(SELECT InteriorRingN('.$affine.', ?) as wkb_intring_geometry '.
                       'FROM '.$table_name.' '.
                      'WHERE ogc_fid = ?'.
                     ') as source'
              ) or die "Can't prepare statement: $DBI::errstr";
        } 


        if (!$sth_origin_polygon_intring_npoints{$table_name})
        {
          $sth_origin_polygon_intring_npoints{$table_name} = 
            $dbh_origin->prepare(
              'SELECT '.
                    'NumPoints(InteriorRingN(wkb_geometry, ?)) as numpoints_intring '.
                       'FROM '.$table_name.' '.
                      'WHERE ogc_fid = ?'
              ) or die "Can't prepare statement: $DBI::errstr";
        } 

print "\nPolygon Interior Rings: ".$hashref->{'num_intrings'}."\n\n";
             
            
        # Loop through the interior rings in the polygon
        foreach $geom_index (1..$hashref->{'num_intrings'})
        {
        
          # We use a windowed approach to selecting individual points from the polygon
          # as otherwise very detailed polygons cause generate_series to exhaust
          # memory on the postgres server.
          my($lower_bound) = 1;
          my($upper_bound) = $pgsql_series_chunk_size;
          my(@node_ids) = ();

          # How many points are in this interior ring?
          my $rc = $sth_origin_polygon_intring_npoints{$table_name}->execute( $geom_index,
                                                                              $hashref->{'ogc_fid'} ) 
            or die "Can't execute statement: $DBI::errstr";
          my $hashref_npoints = $sth_origin_polygon_intring_npoints{$table_name}->fetchrow_hashref;

          while ($lower_bound <= $hashref_npoints->{'numpoints_intring'})
          {
            # trim the upper bound to the actual number of points if necessary
            if ($hashref_npoints->{'numpoints_intring'} < $upper_bound)
            {
              $upper_bound = $hashref_npoints->{'numpoints_intring'};
            }

            print "\nPolygon point windowed query from position '$lower_bound' to position '$upper_bound'...\n";


            my $rc = $sth_origin_polygon_intring_points{$table_name}->execute( 
                                                                               $lower_bound,
                                                                               $upper_bound,
                                                                               $geom_index,
                                                                               $hashref->{'ogc_fid'} ) 
              or die "Can't execute statement: $DBI::errstr";

#            print "Polygon Query will return $sth_origin_polygon_points{$table_name}->{NUM_OF_FIELDS} fields.\n";
#            print "Field names: @{ $sth_origin_polygon_points{$table_name}->{NAME} }\n\n";
            print "Polygon Interior Ring index: $geom_index of ".$hashref->{'num_intrings'}.
                   " with ".$hashref_npoints->{'numpoints_intring'}." points.\n\n";


            while (my $hashref_points = $sth_origin_polygon_intring_points{$table_name}->fetchrow_hashref)
            {
              # Print out row contents for debugging purposes
              foreach $column_name (sort keys %{$hashref_points})
              {
                my($column_value) = $hashref_points->{$column_name};
          
#                print "  Column name: '$column_name'\n";
#                print "    Column value: '$column_value'\n";
        
        
              }
          
              my($node_id) = Node_Insert( $hashref_points->{'srid_point'} );
          
              push(@node_ids, $node_id);
            }
            
            # adjust window for next pass
            $lower_bound = ($upper_bound + 1);
            $upper_bound += $pgsql_series_chunk_size;
            
          }

          Way_and_Tags_Insert('A', $multipolygon_relation_id, 'inner', $hashref, @node_ids);
 
        } # for each interior ring

      } # if ($hashref->{'type_geometry'} eq 'POLYGON')

      
      
#      # Bind the polygon inner and outer rings into a relationship
#      if ($hashref->{'type_geometry'} eq 'POLYGON')
#      {
#        print "\nOuter Ring Way IDs are: ".join(', ', @way_ids_outer_ring).".";
#        print "\nInner Ring Way IDs are: ".join(', ', @way_ids_inner_rings).".";
#     
#      } # if ($hashref->{'type_geometry'} eq 'POLYGON')
      

      # Deal with MultiPolygons
      if ($hashref->{'type_geometry'} eq 'MULTIPOLYGON')
      {
        my($multipolygon_relation_id) = undef;

        # Loop through the polygons in the multipolygon
        foreach $geom_index (1..$hashref->{'num_geometries'})
        {

          print "Inspecting polygon $geom_index in the multipolygon fid ".$hashref->{'ogc_fid'}."...\n";
        
          # Get number of points in the exterior ring
          if (!$sth_origin_multipolygon_numextpoints{$table_name})
          {
            $sth_origin_multipolygon_numextpoints{$table_name} = 
              $dbh_origin->prepare(
                'SELECT '.
                      'NumInteriorRings('.
                         'ST_GeometryN(wkb_geometry, ?)'.
                       ') as num_intrings, '.
                      'NumPoints(ExteriorRing('.
                         'ST_GeometryN(wkb_geometry, ?)'.
                       ')) as numpoints_extring '.
                         'FROM '.$table_name.' '.
                        'WHERE ogc_fid = ?'
                ) or die "Can't prepare statement: $DBI::errstr";
          }
          my $rc = $sth_origin_multipolygon_numextpoints{$table_name}->execute(
                                                                     $geom_index,
                                                                     $geom_index,
                                                                     $hashref->{'ogc_fid'} )
            or die "Can't execute statement: $DBI::errstr";

          my($num_intrings);
          my($numpoints_extring);
          if (my $hashref_numextpoints = $sth_origin_multipolygon_numextpoints{$table_name}->fetchrow_hashref)
          {
            $num_intrings      = $hashref_numextpoints->{'num_intrings'};
            $numpoints_extring = $hashref_numextpoints->{'numpoints_extring'};
          }
          
          print "\nPolygon $geom_index has $numpoints_extring points in its exterior ring...\n";
          
          # Extract points of polygon
          
          ############ TODO: OPTIMISE THIS PREPARED STATEMENT
          if (!$sth_origin_multipolygon_points{$table_name})
          {
            $sth_origin_multipolygon_points{$table_name} = 
              $dbh_origin->prepare(
                'SELECT '.
                      'SetSRID(PointN(wkb_extring_geometry, '.
  #                                   'generate_series(1, NPoints(wkb_extring_geometry))), 4326) as srid_point '.
  #                                   'generate_series(1, 3)), 4326) as srid_point '.
                                     'generate_series(?::int, ?::int)), 4326) as srid_point '.
                'FROM '.
                       '(SELECT ExteriorRing('.
                         'ST_GeometryN(wkb_geometry, ?)'.
                       ') as wkb_extring_geometry '.
                         'FROM '.$table_name.' '.
                        'WHERE ogc_fid = ?'.
                       ') as source'
                ) or die "Can't prepare statement: $DBI::errstr";
          }
          
                
          
          # We use a windowed approach to selecting individual points from the polygon
          # as otherwise very detailed polygons cause generate_series to exhaust
          # memory on the postgres server.
          my($lower_bound) = 1;
          my($upper_bound) = $pgsql_series_chunk_size;
          my(@node_ids) = ();

          while ($lower_bound <= $numpoints_extring)
          {
            # trim the upper bound to the actual number of points if necessary
            if ($numpoints_extring < $upper_bound)
            {
              $upper_bound = $numpoints_extring;
            }

            print "\nPolygon point windowed query of polygon $geom_index of fid ".$hashref->{'ogc_fid'}." from position '$lower_bound' to position '$upper_bound'...\n";

            my $rc = $sth_origin_multipolygon_points{$table_name}->execute( 
                                                                       $lower_bound,
                                                                       $upper_bound,
                                                                       $geom_index,
                                                                       $hashref->{'ogc_fid'} )
              or die "Can't execute statement: $DBI::errstr";

#            print "MultiPolygon Query will return $sth_origin_multipolygon_points{$table_name}->{NUM_OF_FIELDS} fields.\n";
#            print "Field names: @{ $sth_origin_multipolygon_points{$table_name}->{NAME} }\n\n";


            while (my $hashref_points = $sth_origin_multipolygon_points{$table_name}->fetchrow_hashref)
            {
              # Print out row contents for debugging purposes
              foreach $column_name (sort keys %{$hashref_points})
              {
                my($column_value) = $hashref_points->{$column_name};
            
#                print "  Column name: '$column_name'\n";
#                print "    Column value: '$column_value'\n";
          
          
              }
#print ":";            
              my($node_id) = Node_Insert( $hashref_points->{'srid_point'} );
            
              push(@node_ids, $node_id);
            } 
            
            # adjust window for next pass
            $lower_bound = ($upper_bound + 1);
            $upper_bound += $pgsql_series_chunk_size;
            
          }

  #        my($way_id) = Way_Insert( @node_ids );
  #        Way_Tags_Insert( $hashref, $way_id );

#          if ($num_intrings > 0)
#          {
          # Force as the outer ring of a multipolygon
          $multipolygon_relation_id = 
            Way_and_Tags_Insert('A', $multipolygon_relation_id, 'outer', $hashref, @node_ids);
#          }
#          else
#          {
#            # Try and insert this as a simple closed way
#            # (which will work if <= 2000 nodes)
#            # 
#            $multipolygon_relation_id = 
#              Way_and_Tags_Insert('A', $multipolygon_relation_id, 'outer', $hashref, @node_ids);
#          }    
   
print "Multipolygon Relation ID = $multipolygon_relation_id\n";

          # Extract points of polygon interior rings
     
          ############ TODO: OPTIMISE THIS PREPARED STATEMENT
          if (!$sth_origin_multipolygon_intring_points{$table_name})
          {
            $sth_origin_multipolygon_intring_points{$table_name} = 
              $dbh_origin->prepare(
                'SELECT '.
                      'SetSRID(PointN(wkb_intring_geometry, '.
  #                                   'generate_series(1, '.
  #                                     'NPoints(wkb_intring_geometry))),'.
                                     'generate_series(?::int, ?::int)), 4326) as srid_point '.
                'FROM '.
                       '(SELECT InteriorRingN('.
                           'ST_GeometryN(wkb_geometry, ?)'.
                         ', ?) as wkb_intring_geometry '.
                         'FROM '.$table_name.' '.
                        'WHERE ogc_fid = ?'.
                       ') as source'
                ) or die "Can't prepare statement: $DBI::errstr";
          } 


          if (!$sth_origin_multipolygon_intring_npoints{$table_name})
          {
            $sth_origin_multipolygon_intring_npoints{$table_name} = 
              $dbh_origin->prepare(
                'SELECT '.
                      'NumPoints(InteriorRingN('.
                         'ST_GeometryN(wkb_geometry, ?)'.
                       ', ?)) as numpoints_intring '.
                         'FROM '.$table_name.' '.
                        'WHERE ogc_fid = ?'
                ) or die "Can't prepare statement: $DBI::errstr";
          } 

print "\nPolygon Interior Rings: ".$num_intrings."\n\n";

          # Loop through the interior rings in the polygon
          foreach $intring_index (1..$num_intrings)
          {
          
            # We use a windowed approach to selecting individual points from the polygon
            # as otherwise very detailed polygons cause generate_series to exhaust
            # memory on the postgres server.
            my($lower_bound) = 1;
            my($upper_bound) = $pgsql_series_chunk_size;
            my(@node_ids) = ();

            # How many points are in this interior ring?
            my $rc = $sth_origin_multipolygon_intring_npoints{$table_name}->execute( $geom_index,
                                                                                      $intring_index,
                                                                                $hashref->{'ogc_fid'} ) 
              or die "Can't execute statement: $DBI::errstr";
            my $hashref_npoints = $sth_origin_multipolygon_intring_npoints{$table_name}->fetchrow_hashref;

            while ($lower_bound <= $hashref_npoints->{'numpoints_intring'})
            {
              # trim the upper bound to the actual number of points if necessary
              if ($hashref_npoints->{'numpoints_intring'} < $upper_bound)
              {
                $upper_bound = $hashref_npoints->{'numpoints_intring'};
              }

              print "\nPolygon point windowed query from position '$lower_bound' to position '$upper_bound'...\n";


              my $rc = $sth_origin_multipolygon_intring_points{$table_name}->execute( 
                                                                                 $lower_bound,
                                                                                 $upper_bound,
                                                                                 $geom_index,
                                                                                 $intring_index,
                                                                                 $hashref->{'ogc_fid'} ) 
                or die "Can't execute statement: $DBI::errstr";

  #            print "Polygon Query will return $sth_origin_polygon_points{$table_name}->{NUM_OF_FIELDS} fields.\n";
  #            print "Field names: @{ $sth_origin_polygon_points{$table_name}->{NAME} }\n\n";
              print "Polygon Interior Ring index: $intring_index of ".$num_intrings.
                     " with ".$hashref_npoints->{'numpoints_intring'}." points.\n\n";


              while (my $hashref_points = $sth_origin_multipolygon_intring_points{$table_name}->fetchrow_hashref)
              {
                # Print out row contents for debugging purposes
                foreach $column_name (sort keys %{$hashref_points})
                {
                  my($column_value) = $hashref_points->{$column_name};
            
  #                print "  Column name: '$column_name'\n";
  #                print "    Column value: '$column_value'\n";
          
          
                }
            
                my($node_id) = Node_Insert( $hashref_points->{'srid_point'} );
            
                push(@node_ids, $node_id);
              }
              
              # adjust window for next pass
              $lower_bound = ($upper_bound + 1);
              $upper_bound += $pgsql_series_chunk_size;
              
            }

            Way_and_Tags_Insert('A', $multipolygon_relation_id, 'inner', $hashref, @node_ids);
   
          } # for each interior ring

        } # foreach polygon in the multipolygon
        
      } # if ($hashref->{'type_geometry'} eq 'MULTIPOLYGON')


      
      # Extract plain points
      if ($hashref->{'type_geometry'} eq 'POINT')
      {
        my($node_id) = Node_Insert( $hashref->{'srid_geometry'} );
        
        Node_Tags_Insert( $hashref, $node_id );
      }

#      print "END OF RECORD\n\n\n";


      # Now test to see if we've gone over the limit
      print "\nDealt with row #".$origin_row_number.", in table ".$table_name.", element # now ".$changeset_element_count.".\n";
      
      if ($changeset_element_count > $osmapi_changeset_chunk_size)
      {
        # uh oh, roll back the last transaction,
        # tell the user what to do next and wrap it up.
        
        # TODO
        $dbh_destination->rollback();
        
        print "\n\nCHANGESET LIMIT REACHED!\n\n";
        
        print 

        print "\n".
               "Destination database is now ready for use by\n".
               "  'osmosis --read-pgsql ...  --dataset-dump ...  --derive-change'.\n\n";

        print "After you have used osmosis on the destination database,\n".
               "change this script so that:\n".
               '    $start_origin_from_table = '."'".$table_name."'"."\n".
               '    $start_origin_from_row   = '.$origin_row_number."\n\n".
               "Then run this script again for the next pass.\n";
               
        exit;

      }
      else
      {
        # Safe to commit the transaction!
        $dbh_destination->commit();
#exit;        
        $origin_row_number++;
      }
      
    }
    
     

    print "END OF TABLE\n\n\n\n";
    
  }



  # Clean up database connection

  $dbh_origin->disconnect;
  $dbh_destination->disconnect;
  
  print "\n".
         "Destination database is now ready for use by\n".
         "  'osmosis --read-pgsql ...  --dataset-dump ...  --derive-change'.\n\n";

  print "It has ".$changeset_element_count." changeset elements in it.\n\n";
  
  print "If this number is greater than ".$osmapi_changeset_chunk_size."\n".
         "  then you may have difficulties uploading it to the OSM API.\n\n";
  
##
## ENDS
##
