BEGIN{
	pid="";
	
	led=0;
	hqSrt=-1;
	hqEnd=-1;
	
	hqMask="";
	stMask="";
}
{
	cid=$1"\t"$2;
	
	if(cid!=pid){
		if(pid!=""){
			if(hqSrt>=0){hqMask=hqMask""(hqEnd-hqSrt)"H";}
			
			print pid"\t"hqMask"\t"stMask;
		}
		
		pid=cid;
		
		led=0;
		hqSrt=-1;
		hqEnd=-1;
		
		hqMask="";
		stMask="";
		
		if($3!=0){
			hqMask=hqMask""$3"G";
			stMask=stMask""$3"G";
		}
	};
	
	
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