#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id$

require "optparse"
require "nkf"
require "MeCab"

$:.push ".."
require "id2doc.rb"
require "freqfiles.rb"

$KCODE = "e"

alpha = 0.5
opt = OptionParser.new

weight_query_type = {
   :DEFINITION => 0.5,
   :BIOGRAPHY  => 0.5,
   :RELATIONSHIP => 0.5,
   :EVENT      => 0.5,
   :WHY        => 0.5,
   :PERSON     => 0.5,
}

docs = {}
words = {}
ARGF.each do |line|
   line = NKF.nkf( "-Wem0", line.chomp )
   case line
   when /^###/
      if not docs.empty?
         docs.keys.sort_by{|e| -docs[e] }.each do |docid|
            next if docs[ docid ] === 0
            puts [ docid, "%0.10f" % docs[ docid ]  ].join( "\t" )
         end
      end
      #p words
      puts line
      docs = {}
      words = {}
   when /^#/
      puts line
      if line =~ /\A##\s*df\(([^\)]+?)\)\s*:\s*(\d+)\Z/
         words[ $1 ] = $2.to_i
      end
   else
      docid, weight = line.chomp.split( /\t/ )
      text = id2doc( docid, ".." )
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
            #next if geo_score == 0 and time_score == 0
            #puts sentence_text
            #p [ geo_score, time_score ]
            score = 0
            weight_query_type.each_key do |type|
               if weight_query_type[ type ]
                  weight = weight_query_type[ type ]
                  case type
                  when :WHEN
                     k_score = 0
                     sentence_text = lines[0..-2].map{|l| l.split(/\t/)[0] }.join
                     sentence_text.gsub( /[\d\'一二三四五六七八九十○〇昨今]+年/ ){|m| score += 1 }
                     sentence_text.gsub( /[\d一二三四五六七八九十○〇昨今]+月/ ){|m| score += 2 }
                     sentence_text.gsub( /[\d一二三四五六七八九十○〇昨今]+日/ ){|m| score += 5 }
                     score += weight * k_score / lines.size
                  when :EVENT
                     #geo_score -= lines.select{|l| l.split( /\t/ )[1] =~ /地域,国/ }.size * 0.5
                     k_score = lines.select{|l| l.split( /\t/ )[1] =~ /地域/ }.size
                     score += weight * k_score / lines.size
                  end
               end
            end
            total_score += score / words[w]
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
