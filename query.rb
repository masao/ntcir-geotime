#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require "rexml/document"
require "io/nonblock"

require "freqfiles.rb"

topics = REXML::Document.new( open "GeoTime-EN-JA-Topics_ntcirEdited_10.xml" )
topics.elements.each( '//TOPIC' ) do |t|
   STDERR.puts "### #{ t.attributes[ 'ID' ] }"
   d = t.elements.each( './DESCRIPTION' ) do |d|
      next if not d.attributes['LANG'] == "JA"
      text = d.text.sub( /\A<!\[CDATA\[/, "" ).sub( /\]\]>\Z/, "" )
      # text << " 訃報 / 死去" if text =~ /亡くな/
      q = extract_keywords_mecab( text )
      open( "| ./search.pl geotime", "w" ) do |io|
         io.puts q.map{|e| e[0] }
      end
   end
end
