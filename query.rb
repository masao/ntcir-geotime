#!/usr/bin/env ruby
# $Id$

require "rexml/document"

topics = REXML::Document.new( open "GeoTime-EN-JA-Topics_ntcirEdited_10.xml" )
topics.elements.each( '//TOPIC' ) do |t|
   puts "### #{ t.attributes[ 'ID' ] }"
   d = t.elements.each( './DESCRIPTION' ) do |d|
      next if not d.attributes['LANG'] == "JA"
      #p d
      puts d.text.sub( /\A<!\[CDATA\[/, "" ).sub( /\]\]>\Z/, "" )
   end
end

# topics.each do |q|
#    res_file = ".GC-#{q.num}.res"
#    next if File.exist?(res_file)
#    open("|./jma.pl | time ./search.pl -n 1000 -d #{ARGV.join(" ")}", "w") do |f|
#       f.puts q.title.split(/,/).join(" ")
#    end
# end
