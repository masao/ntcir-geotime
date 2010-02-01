# trec-to-geotime.awk                      Fredric Gey  Jan 28, 2010   
# to transform from trec run format to geotime run format
# usage awk -f trec2-to-geotime.awk (TREC-RUN) | sed -f quote.sed >(RUNID)
# e.g.  awk -f trec2-to-geotime.awk BK_T2_DN_SAMPLE | sed -f quote.sed >BRKLY-EN-JA-01-DN
# e.g.
# after changing RUNID and DESCRIPTION (and possibly RUN_TYPE) contents
BEGIN { g = "'" ; LASTTOPICID = "GeoTime-0001"
print "<?xml version='1.0' encoding='UTF-8'?>"
print "<TOPIC_SET>"
print "  <METADATA>"
print "    <RUNID>M-JA-JA-01-D</RUNID>"          # replace with your run ID
#          replace with your brief system description
print "    <DESCRIPTION>Baseline system based on BM25 model with extraction of compound nouns, using DESCRIPTION text from topics.</DESCRIPTION>"
print "    <RUN_TYPE>Automatic</RUN_TYPE>"            #replace Automatic with Manual if manual query development or interactive results process
print "  </METADATA>"
      }
{
 TOPICID=$1; DOCID=$3; RANK=$4+1; SCORE=$5;
if(RANK==1 && TOPICID != LASTTOPICID) {print "    </GEOTIME_RESULT>"
                print "  </TOPIC>"
  }
if(RANK==1) {print "  <TOPIC ID=" g TOPICID g">" 
            print "    <GEOTIME_RESULT>"
            LASTTOPICID = TOPICID
           }
 print "      <DOCUMENT RANK='"RANK "' DOCID='" DOCID "' SCORE='" SCORE "' />"
}
END{print "    </GEOTIME_RESULT>"
     print "  </TOPIC>"
     print "</TOPIC_SET>"
    }
