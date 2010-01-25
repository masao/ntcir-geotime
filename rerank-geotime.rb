#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id$

require "nkf"
require "MeCab"
require "id2doc.rb"
require "freqfiles.rb"

# $KCODE = "e"

ALPHA = 0.5

docs = {}
words = {}
ARGF.each do |line|
   case line
   when /^###/
      if not docs.empty?
         docs.keys.sort_by{|e| -docs[e] }.each do |docid|
            next if docs[ docid ] === 0
            puts [ docid, "%0.10f" % docs[ docid ]  ].join( "\t" )
         end
      end
      puts line
      docs = {}
      words = {}
   when /^#/
      puts line
      if line =~ /^##\s*df\((.+?)\)\s*:\s*(\d+)$/
         words[ NKF.nkf( "-We", $1 ) ] = $2.to_i
      end
   else
      docid, weight = line.chomp.split( /\t/ )
      text = id2doc( docid )
      text = $1 if text =~ /<TEXT>(.+?)<\/TEXT>/m
      text = NKF.nkf( "-em0XZ1", text.strip ).downcase
      #p text
      total_score = 0
      mecab = MeCab::Tagger.new
      #puts text
      text.split( /。/m ).each do |sentence|
         lines = mecab.parse( sentence ).split( /\n/ )
         #puts lines
         matched_words = words.keys & lines.map{|l| l.split( /\t/ )[0] }
         #p lines
         next if matched_words.empty?
         #puts sentence
         #p matched_words
         matched_words.each do |w|
            geo_score = lines.select{|l| l.split( /\t/ )[1] =~ /地域/ }.size
            #geo_score -= lines.select{|l| l.split( /\t/ )[1] =~ /地域,国/ }.size * 0.5
            time_score = 0
            sentence_text = lines[0..-2].map{|l| l.split(/\t/)[0] }.join
            sentence_text.gsub( /[\d\'一二三四五六七八九十○〇昨今]+年/ ){|m| time_score += 1 }
            sentence_text.gsub( /[\d一二三四五六七八九十○〇昨今]+月/ ){|m| time_score += 2 }
            sentence_text.gsub( /[\d一二三四五六七八九十○〇昨今]+日/ ){|m| time_score += 5 }
            next if geo_score == 0 and time_score == 0
            #puts sentence_text
            #p [ geo_score, time_score ]
            score = ALPHA * geo_score / lines.size + (1-ALPHA) * time_score / lines.size
            total_score += score / Math.log2( words[w]+1 )
            #score = weight.to_f * score
            #score = (1-ALPHA) * time_score / lines.size
            #score = time_score
         end
      end
      docs[ docid ] = total_score
      #puts [ docid, total_score ].join( "\t" )
   end
end
if not docs.empty?
   docs.keys.sort_by{|e| -docs[e] }.each do |docid|
      next if docs[ docid ] === 0
      puts [ docid, docs[ docid ]  ].join( "\t" )
   end
end
