function get_library_flag(str,srMax){
	gsub(/[[:digit:]]+(L|B)/,"",str);
	gsub(/[[:digit:]]+A/,"A",str);
	gsub(/A+/,"A",str);
	
	if(length(gensub(/[^A]+/,"","g",str))>=2 && str!~/S[[:digit:]]+S/){
		gsub(/S/,"",str);
		
		sub(/^[^A]*A/,"",str);
		sub(/A[^A]*$/,"",str);
		
		gsub(/A/,",",str);
		
		split(str,sr,",");
		
		asort(sr);
		
		if(sr[1]>=(srMax*0.7)){return 1}
	}
	
	return 0;
}

BEGIN{}
{
	#-	Compute polymerase (ZMW) read length
	prLen=0;
	prStr=$3
	sub(/[[:alpha:]]$/,"",prStr);
	gsub(/[[:alpha:]]/,"_",prStr);
	prCnt=split(prStr,p,"_");
	
	for(i=1;i<=prCnt;++i){prLen+=p[i];}
	#-
	
	
	#-	Count HQ regions, compute total HQ sequence, and get longest HQ segment
	hqTot=0;
	hqMax=0;
	hqStr=gensub(/[[:digit:]]+L/,"","g",$3);
	sub(/H$/,"",hqStr);
	hqCnt=split(hqStr,h,"H");
	
	if(hqCnt>0){
		asort(h);
		
		hqMax=h[hqCnt];
		
		for(i=1;i<=hqCnt;++i){hqTot+=h[i];}
	}
	#-
	
	
	#-	Count subreads and get longest subread
	srTot=0;
	srMax=0;
	srStr=gensub(/[[:digit:]]+[ABFL]/,"","g",$4);
	sub(/S$/,"",srStr);
	srCnt=split(srStr,s,"S");
	
	if(srCnt>0){
		asort(s);
		
		srMax=s[srCnt];
		
		for(i=1;i<=srCnt;++i){srTot+=s[i];}
	}
	#-
	
	
	#-	Count adapters
	aCnt=length(gensub(/[^A]+/,"","g",$4));
	#-
	
	
	#-	Count barcodes
	bCnt=length(gensub(/[^B]+/,"","g",$4));
	#-
	
	
	#-	Count filtered reads
	fCnt=length(gensub(/[^F]+/,"","g",$4));
	#-
	
	
	#-	Check whether read can be used to estimate library size distribution
	lFlg=0;
	
	if(srCnt>=1 && fCnt==0 && aCnt>=2){
		lFlg=get_library_flag($4,srMax);
	}
	#-

	printf "%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\n",$1,$2,prLen,hqTot,hqMax,srTot,srMax,hqCnt,srCnt,aCnt,bCnt,fCnt,lFlg,$4;
}
END{}
