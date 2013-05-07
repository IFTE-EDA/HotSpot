#!/usr/bin/perl -w
#This script helps to generate an SVG figure.
#(More informaiton about SVG can be found at http://www.w3.org/TR/SVG/). 
#SVG figures can be zoomed without losing resolutions.
#
#USAGE: grid_thermal_map.pl <flp_file> <grid_temp_file> > <filename>.svg
#
#Use IE or SVG Viewer to open "<filename>.svg". May need to enable XML
#in your IE. Also, in Linux, ImageMagick 'convert' could be used to convert
#it to other file formats 
#(eg `convert -font Helvetica <filename>.svg <filename>.pdf`).
#
#Inputs: 
#	(1) A floorplan file with the same format as the other HotSpot .flp files.
#	(2) A list of grid temperatures, with the format of each line: 
#      <grid_number>	<grid_temperature>
#	Example floorplan file (example.flp) and the corresponding grid 
#	temperature file (example.t) are inlcuded in this release. The resulting
#	SVG figure (example.svg) is also included. 
#
#Acknowledgement: The HotSpot developers would like to thank Joshua Rosenbluh 
#at Grinnell College, Iowa, for his information and help on the SVG figures.

use strict;

sub usage () {
    print("usage: grid_thermal_map.pl <flp_file> <grid_temp_file> > <filename>.svg (or)\n");
    print("       grid_thermal_map.pl <flp_file> <grid_temp_file> <rows> <cols> > <filename>.svg\n");
    print("       grid_thermal_map.pl <flp_file> <grid_temp_file> <rows> <cols> <min> <max> > <filename>.svg\n");
	print("prints an 'SVG' format visual thermal map to stdout\n");
    print("<flp_file>       -- path to the file containing the floorplan (eg: ev6.flp)\n");
    print("<grid_temp_file> -- path to the grid temperatures file (eg: sample.t)\n");
    print("<rows>           -- no. of rows in the grid (default 64)\n");
    print("<cols>           -- no. of columns in the grid (default 64)\n");
    print("<min>            -- min. temperature of the scale (defaults to min. from <grid_temp_file>)\n");
    print("<max>            -- max. temperature of the scale (defaults to max. from <grid_temp_file>)\n");
    exit(1);
}

&usage() if (@ARGV != 2 && @ARGV != 4 && @ARGV != 6 || ! -f $ARGV[0] || ! -f $ARGV[1]);

#constants used throughout the program
	my $num_levels=128;			#number of colors used
	my $max_rotate=200; 		#maximum hue rotation
	my $floor_map_path=$ARGV[0];#path to the file containing floorplan
	my $temp_map_path=$ARGV[1]; #path to the grid temperature file 
	my $stroke_coeff=10**-7;	#used to tune the stroke-width
	my $stroke_opacity=0;		#used to control the opacity of the floor plan
	my $smallest_shown=10000;	#fraction of the entire chip necessary to see macro
	my $zoom=10**6;
	my $in_minx=0; my $in_miny=0; my $in_maxx=0; my $in_maxy=0; 
	my $txt_offset=100;
	my $x_bound;


#variables used throughout the program
my $fp  ;#the SVG to draw the floorplan
my $tm  ;#the SVG to draw the thermal map
my $defs;#definitions

my $min_x=10**10;my $max_x=0;
my $min_y=10**10;my $max_y=0;
my $tot_x;my $tot_y;

#Specify grid row and column here
my $row=64; my $col=64;
if (@ARGV >= 4) {
	$row = $ARGV[2];
	$col = $ARGV[3];
}

# define my palette, derived from gnuplot palette
my @palette;

$palette[127]='  0,   0, 144';
$palette[126]='  0,   1, 151';
$palette[125]='  0,   2, 158';
$palette[124]='  0,   3, 165';
$palette[123]='  0,   4, 172';
$palette[122]='  0,   5, 179';
$palette[121]='  0,   6, 186';
$palette[120]='  0,   7, 193';
$palette[119]='  0,   8, 200';
$palette[118]='  0,   8, 207';
$palette[117]='  0,   9, 214';
$palette[116]='  0,  10, 220';
$palette[115]='  0,  11, 227';
$palette[114]='  0,  12, 234';
$palette[113]='  0,  13, 241';
$palette[112]='  0,  14, 248';
$palette[111]='  0,  15, 255';
$palette[110]='  0,  23, 255';
$palette[109]='  0,  31, 255';
$palette[108]='  0,  39, 255';
$palette[107]='  0,  48, 255';
$palette[106]='  0,  55, 255';
$palette[105]='  0,  64, 255';
$palette[104]='  0,  72, 255';
$palette[103]='  0,  80, 255';
$palette[102]='  0,  88, 255';
$palette[101]='  0,  96, 255';
$palette[100]='  0, 104, 255';
$palette[99]='  0, 112, 255';
$palette[98]='  0, 120, 255';
$palette[97]='  0, 128, 255';
$palette[96]='  0, 136, 255';
$palette[95]='  0, 144, 255';
$palette[94]='  1, 151, 254';
$palette[93]='  2, 158, 253';
$palette[92]='  3, 165, 252';
$palette[91]='  4, 172, 251';
$palette[90]='  5, 179, 250';
$palette[89]='  6, 186, 249';
$palette[88]='  7, 193, 248';
$palette[87]='  8, 200, 246';
$palette[86]='  8, 206, 245';
$palette[85]='  9, 213, 244';
$palette[84]=' 10, 221, 243';
$palette[83]=' 11, 227, 242';
$palette[82]=' 12, 234, 241';
$palette[81]=' 13, 241, 240';
$palette[80]=' 14, 248, 239';
$palette[79]=' 15, 255, 238';
$palette[78]=' 23, 255, 230';
$palette[77]=' 31, 255, 222';
$palette[76]=' 40, 255, 214';
$palette[75]=' 47, 255, 206';
$palette[74]=' 56, 255, 198';
$palette[73]=' 63, 255, 191';
$palette[72]=' 72, 255, 183';
$palette[71]=' 80, 255, 175';
$palette[70]=' 88, 255, 167';
$palette[69]=' 96, 255, 159';
$palette[68]='104, 255, 151';
$palette[67]='112, 255, 143';
$palette[66]='120, 255, 135';
$palette[65]='128, 255, 128';
$palette[64]='136, 255, 120';
$palette[63]='144, 255, 112';
$palette[62]='151, 254, 105';
$palette[61]='158, 253,  98';
$palette[60]='165, 252,  91';
$palette[59]='172, 251,  84';
$palette[58]='179, 250,  77';
$palette[57]='186, 249,  70';
$palette[56]='193, 248,  63';
$palette[55]='200, 246,  56';
$palette[54]='207, 245,  49';
$palette[53]='214, 244,  42';
$palette[52]='220, 243,  35';
$palette[51]='227, 242,  28';
$palette[50]='234, 241,  21';
$palette[49]='241, 240,  14';
$palette[48]='248, 239,   7';
$palette[47]='255, 238,   0';
$palette[46]='255, 230,   0';
$palette[45]='255, 222,   0';
$palette[44]='255, 214,   0';
$palette[43]='255, 206,   0';
$palette[42]='255, 199,   0';
$palette[41]='255, 191,   0';
$palette[40]='255, 183,   0';
$palette[39]='255, 175,   0';
$palette[38]='255, 167,   0';
$palette[37]='255, 159,   0';
$palette[36]='255, 151,   0';
$palette[35]='255, 143,   0';
$palette[34]='255, 136,   0';
$palette[33]='255, 127,   0';
$palette[32]='255, 120,   0';
$palette[31]='255, 112,   0';
$palette[30]='254, 105,   0';
$palette[29]='253,  98,   0';
$palette[28]='252,  91,   0';
$palette[27]='251,  84,   0';
$palette[26]='250,  77,   0';
$palette[25]='249,  70,   0';
$palette[24]='248,  63,   0';
$palette[23]='246,  56,   0';
$palette[22]='245,  49,   0';
$palette[21]='244,  42,   0';
$palette[20]='243,  35,   0';
$palette[19]='242,  28,   0';
$palette[18]='241,  21,   0';
$palette[17]='240,  14,   0';
$palette[16]='239,   7,   0';
$palette[15]='238,   0,   0';
$palette[14]='231,   0,   0';
$palette[13]='224,   0,   0';
$palette[12]='217,   0,   0';
$palette[11]='210,   0,   0';
$palette[10]='203,   0,   0';
$palette[9]='196,   0,   0';
$palette[8]='189,   0,   0';
$palette[7]='182,   0,   0';
$palette[6]='175,   0,   0';
$palette[5]='168,   0,   0';
$palette[4]='162,   0,   0';
$palette[3]='155,   0,   0';
$palette[2]='148,   0,   0';
$palette[1]='141,   0,   0';
$palette[0]='134,   0,   0';
	
{#generate the SVG for the floorplan

	#declare variables to be used locally
	my @AoA_flp;#Array of arrays
	my @AoA_grid;
	my $min_t=1000;
	my $max_t=0;
	
	my $unit_cnt=0;
	
	#this section reads the floor map file
	{my $num='\s+([\d.]+)';my $dumb_num='\s+[\d.]+';
	open(FP, "< $floor_map_path")    or die "Couldn't open $floor_map_path for reading: $!\n";
	#input file order: instance name, width, height, minx, miny

	while (<FP>) {
			if (/^(\S+)$num$num$num$num/)
			{	
				$in_minx=$4*$zoom; $in_miny=$5*$zoom; $in_maxx=($4+$2)*$zoom; $in_maxy=($5+$3)*$zoom;
				$min_x=$in_minx if $in_minx<$min_x;$max_x=$in_maxx if $in_maxx>$max_x;
				$min_y=$in_miny if $in_miny<$min_y;$max_y=$in_maxy if $in_maxy>$max_y;
#				$min_t=$6 if $6<$min_t;$max_t=$6 if $6>$max_t;
				push @AoA_flp, [ ($1,$in_minx,$in_miny,$in_maxx,$in_maxy,$6) ] ;
			}								
	}
	
	close(FP);
	}
	$tot_x=$max_x-$min_x;
	$tot_y=$max_y-$min_y;
	$x_bound=$max_x*1.2;
	
	my $grid_h=$tot_y/$row;
	my $grid_w=$tot_x/$col;
	my ($grid_minx,$grid_miny,$grid_maxx,$grid_maxy);
	
	#this section reads the temperature map file
	{my $num1='\s+([\d.]+)';my $dumb_num1='\s+[\d.]+';
	open(TM, "< $temp_map_path")    or die "Couldn't open $temp_map_path for reading: $!\n";
	#input file order: grid#, temperature

	while (<TM>) {
		if (/^(\S+)$num1/)
		{
			$grid_minx=($1%$col)*$grid_w;
			$grid_maxx=($1%$col+1)*$grid_w;
			$grid_miny=(int($1/$col))*$grid_h;
			$grid_maxy=(int($1/$col)+1)*$grid_h;
			$min_t=$2 if $2<$min_t;$max_t=$2 if $2>$max_t;
			push @AoA_grid, [ ($1,$grid_minx,$grid_miny,$grid_maxx,$grid_maxy,$2) ] ;
		}								
	}
	close(TM);
	}
	
# if upper and lower limits need to be specified, do it here
if (@ARGV == 6) {
	$min_t=$ARGV[4];
	$max_t=$ARGV[5];
}
	
	#draw the grid temperatures
	$tm='<g id="floorplan" style="stroke: none; fill: red;">'."\n";
	{
	my ($w1,$h1, $level);
	foreach (@AoA_grid){
		$w1=(@{$_}[3])-(@{$_}[1]);
		$h1=(@{$_}[4])-(@{$_}[2]);
		if ($w1>$tot_x/$smallest_shown && $h1>$tot_y/$smallest_shown){
			if ($max_t > $min_t) {
				$level=int(($max_t-(@{$_}[5]))/($max_t-$min_t)*($num_levels-1));
			} else {
				$level = 0;
			}
			$tm.="\t".'<rect x="'.@{$_}[1] .'" y="'. @{$_}[2] .
			'" width="'.$w1 .'" height="'.$h1 .
			'" style="fill:rgb(' .$palette[$level].')" />'."\n";
		}
	}
	}

	#draw the floorplan
	{
	my ($w,$h, $start_y, $end_y, $txt_start_x, $txt_start_y);
	foreach (@AoA_flp){
		$unit_cnt += 1;
		$w=(@{$_}[3])-(@{$_}[1]);
		$h=(@{$_}[4])-(@{$_}[2]);
		$start_y=$tot_y-@{$_}[2]-$h;
		$end_y=$tot_y-@{$_}[2];
		$txt_start_x=@{$_}[1]+$txt_offset;
		$txt_start_y=$start_y+2*$txt_offset;
		if ($w>$tot_x/$smallest_shown && $h>$tot_y/$smallest_shown){
			$fp.="\t".'<line x1="'.@{$_}[1] .'" y1="'. $start_y .
			'" x2="'. @{$_}[3] .'" y2="'. $start_y .
			'" style="stroke:black;stroke-width:30" />'."\n";
			
			$fp.="\t".'<line x1="'.@{$_}[1] .'" y1="'. $start_y .
			'" x2="'. @{$_}[1] .'" y2="'. $end_y .
			'" style="stroke:black;stroke-width:30" />'."\n";
			
			$fp.="\t".'<line x1="'.@{$_}[3] .'" y1="'. $start_y .
			'" x2="'. @{$_}[3] .'" y2="'. $end_y .
			'" style="stroke:black;stroke-width:30" />'."\n";
			
			$fp.="\t".'<line x1="'.@{$_}[1] .'" y1="'. $end_y .
			'" x2="'. @{$_}[3] .'" y2="'. $end_y .
			'" style="stroke:black;stroke-width:30" />'."\n";
			
			$fp.="\t".'<text x="'.$txt_start_x .'" y="'. $txt_start_y .
			'" fill="black" text_anchor="start" style="font-size:180" > '. @{$_}[0] .' </text>'."\n";
		}
	}
	}

# draw the color scale bar	
	{
	my $i;
	my $txt_ymin;
	my $w2=$max_x*0.05;
	my $h2=$max_y*0.005;
	my $clr_xmin=$max_x*1.1;
	my $clr_ymin=$max_y*0.05;
	my $scale_xmin=$max_x*1.05;
	my $scale_value;
	my $final_scale_value=$min_t+(1/$num_levels)*($max_t-$min_t);
	$final_scale_value=~s/^(\d+)\.(\d)(\d)(\d)\d+/$1\.$2$3$4/;
	
	for ($i=0; $i<$num_levels; $i++) {
		if ($w2>$tot_x/$smallest_shown && $h2>$tot_y/$smallest_shown){
#			$level=int(($max_t-(@{$_}[5]))/($max_t-$min_t)*($num_levels-1));
			$fp.="\t".'<rect x="'.$clr_xmin .'" y="'. $clr_ymin .
			'" width="'.$w2 .'" height="'.$h2 .
			'" style="fill:rgb(' .$palette[$i].'); stroke:none" />'."\n";
			if ($i%13==0) {
				$txt_ymin=$clr_ymin+$h2*0.5;
				$scale_value=($max_t-$min_t)*(1-$i/($num_levels-1))+$min_t;
				$scale_value=~s/^(\d+)\.(\d)(\d)\d+/$1\.$2$3/;
				$fp.="\t".'<text x="'.$scale_xmin .'" y="'. $txt_ymin.
				'" fill="black" text_anchor="start" style="font-size:250" > '. $scale_value .' </text>'."\n";
			}
		}
		$clr_ymin+=$h2;
	}
	$min_t=~s/^(\d+)\.(\d)(\d)\d+/$1\.$2$3/;
	$fp.="\t".'<text x="'.$scale_xmin .'" y="'. $clr_ymin .
	'" fill="black" text_anchor="start" style="font-size:250" > '. $min_t .' </text>'."\n";
	}
	
	$fp.="</g>\n";
}
#svg header and footer
my $svgheader= <<"SVG_HEADER";
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN"
    "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg width="900px" height="500px"
    viewBox="$min_x $min_y $x_bound $max_y">
<title>Sample Temperature Map For HotSpot Grid Model</title>
SVG_HEADER

my $svgfooter= <<"SVG_FOOTER";
</svg>
SVG_FOOTER

print $svgheader.$tm.$fp.$svgfooter;
#writes out the header, definitions, thermal map, floor plan and footer
