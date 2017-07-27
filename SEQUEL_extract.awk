BEGIN{
	FS="\t";
}
{
	# Check "http://pacbiofileformats.readthedocs.io/en/3.0/BAM.html#how-to-annotate-scrap-reads" for documentation of "scraps"-specific fields
	# PacBio read headers (in "$1") depend on the cofiguration of the sequencer. We use: "m54097_170223_195514/5047037/70_6449"
	
	#    h[1]-h[3]:    Metadata Context Id                (e.g. "m54097_170223_195514")
	#    h[4]     :    ZMW ID                             (e.g. "5047037")
	#    h[5]-h[6]:    Start & End coordinate in ZMW read (e.g. "70_6449")
	
	if(rtype=="scraps"){
		if($22=="sz:A:N"){
			t=$21;
			sub(/sc\:A\:/,"",t);
			
			split($1,h,"/|_");
			printf "%s_%s_%s\t%d\t%d\t%d\t%s\n",h[1],h[2],h[3],h[4],h[5],h[6],t;
		}
	}
	else{
		if(rtype=="subreads"){
			split($1,h,"/|_");
			printf "%s_%s_%s\t%d\t%d\t%d\tS\n",h[1],h[2],h[3],h[4],h[5],h[6];
		}
		else{
			print "\n[SEQUEL_extract.awk]:\tUnknown read type!";
			exit 1;
		}
	}
}
END{}