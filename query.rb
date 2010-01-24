#!/usr/bin/env ruby
# $Id$

require "rexml/document"
require "io/nonblock"

require "freqfiles.rb"

# $stdout.nonblock = true

topics = REXML::Document.new( open "GeoTime-EN-JA-Topics_ntcirEdited_10.xml" )
topics.elements.each( '//TOPIC' ) do |t|
   STDERR.puts "### #{ t.attributes[ 'ID' ] }"
   d = t.elements.each( './DESCRIPTION' ) do |d|
      next if not d.attributes['LANG'] == "JA"
      text = d.text.sub( /\A<!\[CDATA\[/, "" ).sub( /\]\]>\Z/, "" )
      q = extract_keywords_mecab( text )
      open( "| ./search.pl geotime", "w" ) do |io|
         io.puts q.map{|e| e[0] }
      end
   end
end

# topics.each do |q|
#    res_file = ".GC-#{q.num}.res"
#    next if File.exist?(res_file)
#    open("|./jma.pl | time ./search.pl -n 1000 -d #{ARGV.join(" ")}", "w") do |f|
#       f.puts q.title.split(/,/).join(" ")
#    end
# end
