#!/usr/bin/env ruby
# $Id$

lineno = nil
ARGV.each do |f|
   open( f ).each do |line, i|
      case line
      when /^<DOC>/
         lineno = $.
      when /^<DOCNO>(\S+)<\/DOCNO>/
         puts "#{ $1 }\t#{ f }\t#{ lineno }"
      end
   end
end
