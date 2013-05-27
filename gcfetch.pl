#!/usr/bin/perl -w
# gcfetch
# Morgan Terry
# June 1, 2003
#
# read geocache information from .loc file from geocaching.com 
# and download the cache descriptions.

use strict;
use XML::Twig;
use LWP::UserAgent;
use HTML::FormatText;
use HTML::TreeBuilder;

# TODO: handle command-line args for this.
my $outdir = "./geocaches";
my $watchlist = "./watchlist_links";

my $twig = XML::Twig->new();
my $ua = LWP::UserAgent->new(agent => "gcfetch"); # site doesn't like libwww
my $formatter = HTML::FormatText->new;

my ($waypoint, $id, $lat, $lon, $url, $name);
my ($outfile, $response, $tree, $f, $wl);

# make sure our output dir exists
if (! -d $outdir) {
  mkdir($outdir);
}

# open watchlist file
open($wl, ">>$watchlist");

# process the .loc files
foreach my $file (@ARGV) {
	
	$twig->parsefile($file);

	foreach $waypoint ($twig->root->children('waypoint')) {
		$id   = $waypoint->first_child('name')->att('id');
		$lat  = $waypoint->first_child('coord')->att('lat');
		$lon  = $waypoint->first_child('coord')->att('lon');
		$url  = $waypoint->first_child_text('link'); 
		$name = $waypoint->first_child('name')->text;
	
		$outfile = "$outdir/$id";
	
		# TODO: only output stuff if a verbose option is specified
		print "Cache Name: $name\n";
		print "  Waypoint: $id\n";
		print "    Coords: lat=$lat lon=$lon\n";
		print "       URL: $url\n";
	
		#$response = $ua->get("$url\&pf=y", ':content_file' => $outfile);
		$response = $ua->get("$url\&pf=y");
	
		die "Error while getting $response->request->uri -- $response->status_line \nAborting" 
		unless $response->is_success;
	
		$tree = HTML::TreeBuilder->new;
		$tree->parse($response->content);
		$tree->eof;
		
		open($f, ">$outfile");
		
		print $f "$id\: $name\n";
		print $f $formatter->format($tree);

		close($f);
		$tree = $tree->delete;

		print $wl "<a href=\"$url\">$name</a><br/>\n";

		print "Downloaded cache description to $outfile.\n\n";
	}

}

close ($wl);
