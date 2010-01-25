#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id$

require "nkf"
require "MeCab"
require "id2doc.rb"

$KCODE = "e"

ALPHA = 0.0

docs = {}
ARGF.each do |line|
   case line
   when /^###/
      puts line
      if not docs.empty?
         docs.keys.sort_by{|e| -docs[e] }.each do |docid|
            puts [ docid, docs[ docid ]  ].join( "\t" )
         end
      end
      docs = {}
   when /^#/
      puts line
   else
      docid, weight = line.chomp.split( /\t/ )
      text = ""
      IO.popen( "./id2doc.rb #{ docid }" ) do |io|
         io.each do |line|
            text << line
            break if line =~ /^<\/DOC>/
         end
      end
      text = $1 if text =~ /<TEXT>(.+?)<\/TEXT>/m
      text = NKF.nkf( "-em0XZ1", text.strip ).downcase
      #p text
      lines = []
      mecab = MeCab::Tagger.new
      lines = mecab.parse( text ).split( /\n/ )
      geo_score = lines.select{|l| l.split( /\t/ )[1] =~ /地域|組織/ }.size
      geo_score -= lines.select{|l| l.split( /\t/ )[1] =~ /地域,国/ }.size * 0.8
      time_score = 0
      text.gsub( /[\d\'一二三四五六七八九十○〇昨]+年/ ){|m| time_score += 1 }
      text.gsub( /[\d一二三四五六七八九十○〇昨]+月/ ){|m| time_score += 2 }
      text.gsub( /[\d一二三四五六七八九十○〇昨]+日/ ){|m| time_score += 5 }
      score = ALPHA * geo_score / lines.size + (1-ALPHA) * time_score / lines.size
      score = weight.to_f * score
      #score = (1-ALPHA) * time_score / lines.size
      #score = time_score
      docs[ docid ] = score
   end
end
if not docs.empty?
   docs.keys.sort_by{|e| -docs[e] }.each do |docid|
      puts [ docid, docs[ docid ]  ].join( "\t" )
   end
end
