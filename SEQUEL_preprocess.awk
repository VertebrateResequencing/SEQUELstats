BEGIN{
	pid="";
	
	led=0;
	hqSrt=-1;
	hqEnd=-1;
	
	#- CIGAR-like region masks
	hqMask="";	# Quality mask. Each subread should theoretically have only one high quality region ("H") flanked by 0-2 low quality regions ("L").
	stMask="";	# Subread-type mask. Possible IDs ("L" = low quality, "F" = filtered subread, "A" = adapter, "B" = barcode, "S" = valid subread) are taken from the BAM "sc" tag (except "S")
	#- In addition to the above, script will insert a "G" tag should a part of the ZMW read be missing
}
{
	cid=$1"\t"$2;	# The ID for each read consists of the "Metadata Context Id" and "ZMW ID"
	
	if(cid!=pid){
		if(pid!=""){
			if(hqSrt>=0){hqMask=hqMask""(hqEnd-hqSrt)"H";}
			
			print pid"\t"hqMask"\t"stMask;
		}
		
		pid=cid;
		
		led=0;	# "Last end". Used to check whether each subsequent part of a ZMW read starts where the previous one stopped. If not, a part is missing!
		
		hqSrt=-1;
		hqEnd=-1;
		
		hqMask="";
		stMask="";
		
		if($3!=0){
			hqMask=hqMask""$3"G";
			stMask=stMask""$3"G";
		}
	}
	
	
	if(led!=0){
		if($3!=led){
			hqMask=hqMask""($3-led)"G";
			stMask=stMask""($3-led)"G";
		}
	}
	
	led=$4;
	
	
	if($5=="L"){
		if(hqSrt>=0){
			hqMask=hqMask""(hqEnd-hqSrt)"H";
			
			hqSrt=-1;
			hqEnd=-1;
		}
		
		hqMask=hqMask""($4-$3)"L";
		stMask=stMask""($4-$3)"L";
	}
	else{
		if(hqSrt<0){hqSrt=$3;}
		
		hqEnd=$4;
		
		stMask=stMask""($4-$3)""$5;
	}
}
END{
	print pid"\t"hqMask"\t"stMask;
}