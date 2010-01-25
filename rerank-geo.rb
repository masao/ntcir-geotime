#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id$

require "nkf"
require "MeCab"
require "id2doc.rb"

$KCODE = "e"

docs = {}
ARGF.each do |line|
   case line
   when /^#/
      puts line
      docs = {}
   else
      docs = {}
      docid, weight, = line.chomp.split( /\t/ )
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
      docs[ docid ] = lines.select{|l| l.split( /\t/ )[1] =~ /地域|組織/ }.size
      puts [ docid, docs[ docid ].to_f / lines.size ].join( "\t" )
   end
end
