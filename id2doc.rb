#!/usr/bin/env ruby
# $Id$

require "io_bsearch.rb"

IDLIST = "idlist.txt"
def id2doc( docno )
   result = nil
   open( IDLIST ) do |f|
      line = f.bsearch( 0, File.size( IDLIST ) ) do |line|
         this_docno = line.chomp.split( /\t/ )[0]
         docno <=> this_docno
      end
      docno, file, pos = line.chomp.split( /\t/ )
      # system( "tail +#{ lineno } #{ file } | lv" )
      open( file ) do |io|
         io.pos = pos.to_i
         result = ""
         io.each do |line|
            result << line
            break if line =~ /^<\/DOC>/
         end
      end
   end
   result
end

if $0 == __FILE__
   puts id2doc( ARGV[0] )
end
