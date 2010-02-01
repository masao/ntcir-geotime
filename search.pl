#!/usr/bin/env perl
# $Id$

# Usage:
#
# % echo µÈÌûÁ±Î¤°äÀ× | ./jma.pl | /usr/bin/time ./search.pl `ruby -e  'ARGV.each{|i|puts File.basename(i, "cw.c")}' dryrun.wam/*cw.c`

use strict;
use warnings;

use File::Basename;
use lib dirname($0);
require "bm25.pl";

$| = 1;

my %HANDLE_ALIAS = (':geotime' => "geotime",
		    ':cache_N:geotime'		=> 377941,	# caching size
		    ':cache_total:geotime'		=> 89423136,
		   );

my %OPT = ('n' => 100,
	   'k3' => 1000, 'k1' => 1.2, 'b' => 0.75,
	  );

sub usage {
    print "Usage: $0 [-n #] [-d] [-help] [-param] handle ...\n";
    print <<EOF;

	BM25 parameters:

		-k3 1000
		-k1 1.2
		-b  0.75
EOF
    exit;
}

while (defined($ARGV[0]) && $ARGV[0] =~ /^--?(\w+)$/) {
    my $opt = $1;
    if ($opt eq "help") {
	usage();
    } elsif ($opt eq "d") {
	$OPT{$opt} = $opt;
    } elsif ($opt =~ /^n|k3|k1|b$/o) {
	shift @ARGV;
	if (defined $ARGV[0]) {
	    $OPT{$opt} = $ARGV[0];
	} else {
	    usage();
	}
    } else {
	print "WARNING: unknown option: $opt\n";
	usage();
    }
    shift @ARGV;
}

usage() unless defined $ARGV[0];

my @handle = ();
foreach my $h (@ARGV) {
    if (defined $HANDLE_ALIAS{$h}) {
	foreach my $a (split(/\s/, $HANDLE_ALIAS{$h})) {
	    push @handle, $a;
	}
    } else {
	push @handle, $h;
    }
}
my $cache_N = undef;
my $cache_total = undef;
if (@ARGV == 1 && defined $HANDLE_ALIAS{$ARGV[0]}) {
    $cache_N = $HANDLE_ALIAS{":cache_N$ARGV[0]"};
    $cache_total = $HANDLE_ALIAS{":cache_total$ARGV[0]"};
}

my @tmp = <STDIN>;
chomp(@tmp);
my %query = ();
foreach my $q (@tmp) {
    $query{$q}++;
}

my %weight = calc_bm25('handle'	=> \@handle,
		       'cache_N'=> $cache_N,
		       'cache_total'=> $cache_total,
		       'query'	=> \%query,
		       'k3'	=> $OPT{"k3"},
		       'k1'	=> $OPT{"k1"},
		       'b'	=> $OPT{"b"},
		       'debug'	=> $OPT{'d'});

print "## df(". join(' OR ', keys %query) ."): ". scalar(keys %weight) ."\n"
    if scalar(keys %query) > 1;
my $i = 1;
foreach my $d (sort { $weight{$b} <=> $weight{$a} } keys %weight) {
    print "$d\t$weight{$d}\n";
    last if $i >= $OPT{'n'};
    $i++;
}
