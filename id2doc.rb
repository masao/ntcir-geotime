#!/usr/bin/env ruby
# $Id$

require "io_bsearch.rb"

IDLIST = "idlist.txt"

docno = ARGV[0]

open( IDLIST ) do |f|
   line = f.bsearch( 0, File.size( IDLIST ) ) do |line|
      this_docno = line.chomp.split( /\t/ )[0]
      docno <=> this_docno
   end
   docno, file, lineno = line.chomp.split( /\t/ )
   system( "tail +#{ lineno } #{ file } | lv" )
end
