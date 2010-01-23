#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require "kconv"
require "nkf"
require "pp"
require "MeCab"

module Math
   def self::log2( n )
      Math.log10( n ) / Math.log10( 2 )
   end
end

def extract_keywords_mecab( str, method = :default )
   mecab = MeCab::Tagger.new( '--node-format=%m\t%H\t%c\n --unk-format=%m\tUNK\t%c\n' )
   str = NKF.nkf( "-Wem0XZ1", str ).gsub( /\s+/, " " ).strip
   normalized_content = str.downcase
   lines = mecab.parse( normalized_content )
   #puts lines
   lines = lines.toutf8.split( /\n/ ).map{|l| l.split(/\t/) }
   lines_ind = lines.select{|l| l[2] and l[1] =~ /^名詞|UNK|形容詞/o and l[1] !~ /接[頭尾]|非自立|代名詞/o }
   lines_composite = []
   lines.each_with_index do |l, i|
      next if not l[2]
      next if not l[1] =~ /^名詞|UNK|形容詞/o
      next if l[0] =~ /\A[\x00-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f]+\Z/o # ASCII symbol chars
      j = 1
      while lines[ i+j ]
         break if j > 6
         break if not lines[i+j][2]
         break if not lines[i+j][1] =~ /^名詞|UNK|形容詞/o
         break if lines[i+j][0] =~ /\A[\x00-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f]+\Z/o # ASCII symbol chars
         lines_composite << [ lines[i,j+1].map{|e| e[0] }.join,
                              "複合語-" + lines[i,j+1].map{|e| e[1] }.join("|"),
                              lines[i,j+1].inject(0){|sum,num| sum+=num[2].to_i },
                              j
                            ]
         j += 1
      end
   end
   #pp lines_composite
   #pp lines
   raise "Extracting keywords from a text failed." if lines.empty?
   min = lines_ind.map{|e| e[2].to_i }.min
   lines = lines_ind.map{|e| [ e[0], e[1], e[2].to_i + min.abs + 1 ] } if min < 0
   count = Hash.new( 0 )
   score = 0
   lines_ind.each_with_index do |line, idx|
      next if line[0] =~ /\A[\x00-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f]+\Z/o # ASCII symbol chars
      next if line[0] =~ /\A(?:w(?:h(?:e(?:re(?:a(?:[st]|fter)|u(?:nto|pon)|in(?:to)?|o[fn]?|from|with|ver|by)?|n(?:(?:so)?ever|ce)?|ther)|o(?:m(?:(?:so)?ever)?|s(?:oever|e)|ever|le)?|i(?:ch(?:(?:so)?ever)?|l(?:st|e)|ther)|at(?:(?:so)?ever)?|y)|i(?:th(?:out|in)?|ll)|e(?:ll|re)?|ould|as)|a(?:l(?:(?:bei|mos)t|on[eg]|though|ready|ways|so|l)|n(?:y(?:(?:wher|on)e|thing|how)?|other|d)?|fter(?:wards)?|bo(?:ut|ve)|gain(?:st)?|mong(?:st)?|r(?:ound|e)|(?:cros)?s|dj|t)?|t(?:h(?:e(?:re(?:(?:upo|i)n|afte|for|by)?|m(?:selves)?|n(?:ce)?|ir|se|y)?|r(?:ough(?:out)?|u)|o(?:ugh|se)|[iu]s|a[nt])|o(?:gether|wards?|o)?)?|s(?:o(?:me(?:t(?:imes?|hing)|(?:wher|on)e|how)?)?|e(?:em(?:ing|ed|s)?|veral)|(?:inc|am)e|h(?:ould|e)|till|uch)?|b(?:e(?:c(?:om(?:es?|ing)|a(?:us|m)e)|fore(?:hand)?|(?:hi|yo)nd|(?:twe)?en|sides?|ing|low)?|oth|ut|y)|h(?:e(?:r(?:e(?:(?:upo|i)n|by)?|s(?:elf)?)?|eafter|nce)?|i(?:m(?:self)?|s)|a(?:[ds]|ve)|ow(?:ever)?)|o(?:u(?:r(?:(?:selve)?s)?|t)|n(?:ce one|ly|to)?|ther(?:wise|s)?|f(?:ten|f)?|(?:ve)?r|wn)|e(?:ve(?:r(?:y(?:(?:wher|on)e|thing)?)?|n)|ls(?:ewher)?e|(?:noug|ac)h|ither|xcept|tc|g)|n(?:o(?:[rw]|t(?:hing)?|body|o?ne)?|e(?:ver(?:theless)?|ither|xt)|amely|where)|m(?:o(?:re(?:over)?|st(?:ly)?)|(?:eanwhil)?e|u(?:ch|st)|y(?:self)?|an?y|ight)|i(?:[efs]|n(?:deed|to|c)?|t(?:s(?:elf)?)?)?|f(?:or(?:mer(?:ly)?)?|urther|irst|rom|ew)|l(?:a(?:tter(?:ly)?|st)|e(?:ast|ss)|td)|y(?:ou(?:r(?:s(?:el(?:ves|f))?)?)?|et)|x(?:author|other |note|subj|cal)|u(?:n(?:der|til)|p(?:on)?|s)|c(?:an(?:not)?|o(?:uld)?)|d(?:uring|own)|per(?:haps)?|v(?:ery|ia)|rather)\Z/o
      #next if line[0].size < 3
      #p line[2]
      #puts line.join("\t")
      case method
      when :tf
         score = 1
      when :count
         score = line[2].to_i
      else
         score = Math.log2( line[2].to_i + 1 )
      end
      #pp [ line[0], score, idx ]
      count[ line[0] ] += score #/ Math.log2( idx + 1 )
      #count[ line[0] ] += 1
   end
   lines_composite.each_with_index do |line, idx|
      next if line[0] =~ /\A(?:w(?:h(?:e(?:re(?:a(?:[st]|fter)|u(?:nto|pon)|in(?:to)?|o[fn]?|from|with|ver|by)?|n(?:(?:so)?ever|ce)?|ther)|o(?:m(?:(?:so)?ever)?|s(?:oever|e)|ever|le)?|i(?:ch(?:(?:so)?ever)?|l(?:st|e)|ther)|at(?:(?:so)?ever)?|y)|i(?:th(?:out|in)?|ll)|e(?:ll|re)?|ould|as)|a(?:l(?:(?:bei|mos)t|on[eg]|though|ready|ways|so|l)|n(?:y(?:(?:wher|on)e|thing|how)?|other|d)?|fter(?:wards)?|bo(?:ut|ve)|gain(?:st)?|mong(?:st)?|r(?:ound|e)|(?:cros)?s|dj|t)?|t(?:h(?:e(?:re(?:(?:upo|i)n|afte|for|by)?|m(?:selves)?|n(?:ce)?|ir|se|y)?|r(?:ough(?:out)?|u)|o(?:ugh|se)|[iu]s|a[nt])|o(?:gether|wards?|o)?)?|s(?:o(?:me(?:t(?:imes?|hing)|(?:wher|on)e|how)?)?|e(?:em(?:ing|ed|s)?|veral)|(?:inc|am)e|h(?:ould|e)|till|uch)?|b(?:e(?:c(?:om(?:es?|ing)|a(?:us|m)e)|fore(?:hand)?|(?:hi|yo)nd|(?:twe)?en|sides?|ing|low)?|oth|ut|y)|h(?:e(?:r(?:e(?:(?:upo|i)n|by)?|s(?:elf)?)?|eafter|nce)?|i(?:m(?:self)?|s)|a(?:[ds]|ve)|ow(?:ever)?)|o(?:u(?:r(?:(?:selve)?s)?|t)|n(?:ce one|ly|to)?|ther(?:wise|s)?|f(?:ten|f)?|(?:ve)?r|wn)|e(?:ve(?:r(?:y(?:(?:wher|on)e|thing)?)?|n)|ls(?:ewher)?e|(?:noug|ac)h|ither|xcept|tc|g)|n(?:o(?:[rw]|t(?:hing)?|body|o?ne)?|e(?:ver(?:theless)?|ither|xt)|amely|where)|m(?:o(?:re(?:over)?|st(?:ly)?)|(?:eanwhil)?e|u(?:ch|st)|y(?:self)?|an?y|ight)|i(?:[efs]|n(?:deed|to|c)?|t(?:s(?:elf)?)?)?|f(?:or(?:mer(?:ly)?)?|urther|irst|rom|ew)|l(?:a(?:tter(?:ly)?|st)|e(?:ast|ss)|td)|y(?:ou(?:r(?:s(?:el(?:ves|f))?)?)?|et)|x(?:author|other |note|subj|cal)|u(?:n(?:der|til)|p(?:on)?|s)|c(?:an(?:not)?|o(?:uld)?)|d(?:uring|own)|per(?:haps)?|v(?:ery|ia)|rather)\Z/o
      case method
      when :tf
         score = 1
         #score = 1.0 / line[3]
      when :count
         score = line[2].to_i
      else
         score = Math.log2( line[2].to_i + 1 )
         #score = 1.0 / Math.log2( line[3] + 1 )
      end
      #pp [ line[0], score, idx ]
      count[ line[0] ] += score #/ Math.log2( idx + 1 )
      #count[ line[0] ] += 1
   end
   #pp count
   ranks = count.keys.sort_by{|e| count[e] }.reverse.map{|e| [e,count[e]] }
   #pp ranks
   #3.times do |i|
   #   puts [ i+1, ranks[i], count[ ranks[i] ] ].join( "\t" )
   #end
   ranks
end

def freqfile_format( docno, vector )
   result = []
   result
end

if $0 == __FILE__
   count = {}
   within_text = false
   text, headline, docno = nil
   ARGF.each do |line|
      #puts line
      case line
      when /^<DOC>/
         text = ""
         headline, docno = nil
      when /^<DOCNO>(\S+)<\/DOCNO>/
         docno = $1
      when /^<HEADLINE>(.*?)<\/HEADLINE>/
         headline = $1
      when /^<TEXT>/
         within_text = true
      when /^<\/TEXT>/
         within_text = false
      when /^<\/DOC>/
         #p [ docno, headline, text ]
         #headline_w = extract_keywords_mecab( headline, :tf )
         text = [ headline, text ].join( "\n" )
         text_w = extract_keywords_mecab( text, :tf )
         #text_w += headline_w
         #STDERR.puts docno
         puts "@#{ docno }"
         text_w.each do |k, v|
            puts "#{ v } #{ k }"
         end
      else
         if within_text
            text << line
         end
      end
   end
end
