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

my %HANDLE_ALIAS = (':cont' => "000 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020 021 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042 043 044 045 046 047 048 049 050 051 052 053 054 055 056 057 058 059 060 061 062 063 064 065 066 067 068 069 070 071 072 073 074 075 076 077 078 079 080 081 082 083 084 085 086 087 088 089 090 091 092 093 094 095 096 097 098 099 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 diff",
		    ':anchor' => "anchor0 anchor1 anchor2 anchor3",
		    ':cache_N:cont'		=> 94995824,	# caching size
		    ':cache_total:cont'		=> 97508413459,
		    ':cache_N:anchor'		=> 78034958,	# caching size
		    ':cache_total:anchor'	=> 6006654236,
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
