BEGIN{
	FS="\t";
}
{
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