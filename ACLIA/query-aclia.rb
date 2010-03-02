#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

# ACLIA用

require "rexml/document"
require "io/nonblock"

$:.push ".."
require "freqfiles.rb"

topics = REXML::Document.new( open "ACLIA2-JA-T.xml" )
topics.elements.each( '//TOPIC' ) do |t|
   STDERR.puts "### #{ t.attributes[ 'ID' ] }"
   d = t.elements.each( './QUESTION' ) do |d|
      next if not d.attributes['LANG'] == "JA"
      text = d.text.sub( /\A<!\[CDATA\[/, "" ).sub( /\]\]>\Z/, "" )
      # text << " 訃報 / 死去" if text =~ /亡くな/
      q = extract_keywords_mecab( text )
      open( "| ../search.pl #{ ARGV.join(" ") } geotime", "w" ) do |io|
         io.puts q.map{|e| e[0] }
      end
   end
end
