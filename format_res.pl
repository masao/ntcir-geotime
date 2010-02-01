#!/usr/bin/env perl
# $Id$

use strict;
use warnings;

my $runid = shift @ARGV;

my $num = 0;
my $qid = undef;
while (<>) {
    if (/^###\s*([A-Za-z\d\-]+)$/) {
	$qid = $1;
	$num = 0;
    } elsif (/^([A-Z\d\-]+)\t([\d\.e\-]+)$/) {
	print "$qid\t0\t$1\t$num\t$2\t$runid\n" if $num < 100;
	$num++;
    } else {
	print STDERR $_;
    }
}
