#!perl -w
# $Id$

use strict;
use warnings;

use lib "/net/rcirpcc1-fs/disks/disk00/masao/getaroot/ext/";
use lib "/net/rcirpcc1-fs/disks/disk00/masao/getaroot/ext/wam/";
use lib "/net/rcirpcc1-fs/disks/disk00/masao/getaroot/ext/wam/blib/lib/";
use wam;

my $DEBUG = 0;
sub dprint {
    if ($DEBUG) {
	print STDERR @_;
    }
}

sub calc_bm25 {
    my (%param) = @_;
    my @handle = @{$param{'handle'}};
    my $cache_N  = $param{'cache_N'};
    my $cache_total = $param{'cache_total'};
    my %query  = %{$param{'query'}};
    my $bm25_k3= $param{'k3'};
    my $bm25_k1= $param{'k1'};
    my $bm25_b = $param{'b'};

    $DEBUG = $param{'debug'};

    wam::init("");

    my %df = ();
    foreach my $q (sort keys %query) {
	foreach my $h (@handle) {
	    my $wam = wam::open($h);
	    # print wam::id2name($wam, wam::WAM_COL(), 1);
	    if (my $id = wam::name2id($wam, wam::WAM_COL(), $q)) {
		my $hitnum = wam::elem_num($wam, wam::WAM_COL(), $id);
		$df{$q} += $hitnum;
		dprint "$h: [$q](id=$id): $hitnum\n";
	    } else {
		dprint "$h: [$q]: 0\n";
	    }
	    wam::close($wam);
	}
    }

    foreach my $q (map { $_->[0] }
		   sort { $a->[1] <=> $b->[1] }
		   map { [ $_, defined($df{$_}) && $df{$_} ] }
		   keys %query) {
	if (defined($df{$q})) {
	    print "## df($q): $df{$q}\n";
	} else {
	    print "## df($q): 0\n";
	}
    }
    return () if scalar(keys %df) == 0;

    my $N = 0;
    my $total_freq_sum = 0;
    if (defined($cache_N) && defined($cache_total)) {
	$N = $cache_N;
	$total_freq_sum = $cache_total;
    } else {
	foreach my $h (@handle) {
	    my $wam = wam::open($h);
	    my $size = wam::size($wam, wam::WAM_ROW());
	    my $sum  = wam::total_freq_sum($wam, wam::WAM_COL());
	    dprint "$h: wam_size: $size, total_freq_sum: $sum\n";
	    $N += $size;
	    $total_freq_sum += $sum;
	    wam::close($wam);
	}
    }
    my $avg_dlen = $total_freq_sum / $N;
    dprint "## N: $N\n";
    dprint "## total_freq_sum: $total_freq_sum\n";
    dprint "## avg_dlen: $avg_dlen\n";

    my %weight = ();
    foreach my $q (sort { $df{$a} <=> $df{$b} } keys %df) {
	my $bm25_w1 = log(($N - $df{$q} + 0.5) / ($df{$q}+0.5));
	my $wq = $bm25_w1 * ($bm25_k3 + 1) * $query{$q} / ($bm25_k3 +  $query{$q});
	dprint "## wq(t|q):q=[$q]: bm25_w1=$bm25_w1: $wq\n";
	foreach my $h (@handle) {
	    my $wam = wam::open($h);
	    dprint "processing $h get_vec\n";
	    if (my $id = wam::name2id($wam, wam::WAM_COL(), $q)) {
		my $found = wam::get_vec($wam, wam::WAM_COL(), $id);
		foreach my $d (@$found) {
		    my $bm25_dlen = wam::freq_sum($wam, wam::WAM_ROW(), $$d{'id'});
		    my $bm25_K = $bm25_k1 * ((1 - $bm25_b) + $bm25_b * $bm25_dlen / $avg_dlen);
		    my $wdt = $wq * ($bm25_k1 + 1) * $$d{'freq'} / ($bm25_K + $$d{'freq'});
		    $weight{$$d{'name'}} += $wdt;
		    # dprint "$$d{'name'}(id=$$d{'id'}):\t$$d{'freq'}\t$wdt: dlen=$bm25_dlen,K=$bm25_K\n";
		}
	    }
	    wam::close($wam);
	}
    }
    return %weight;
}

1;
