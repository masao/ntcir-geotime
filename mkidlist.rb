#!/usr/bin/env ruby
# $Id$

pos = nil
ARGV.each do |f|
   open( f ) do |io|
      io.each do |line|
         case line
         when /^<DOC>/
            pos = io.pos - line.size
         when /^<DOCNO>(\S+)<\/DOCNO>/
            puts "#{ $1 }\t#{ f }\t#{ pos }"
         end
      end
   end
end
