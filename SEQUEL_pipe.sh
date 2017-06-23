path="${1}"
list="${2}"
line="${3}"

preprocess="/nfs/users/nfs_d/ddd1/Work/Projects/004_Assembly_pipelines/Scripts/Awk/preprocess_pacbio_header_data.awk"
process="/nfs/users/nfs_d/ddd1/Work/Projects/004_Assembly_pipelines/Scripts/Awk/process_preprocessed_header_data.awk"
sequelstats="/nfs/users/nfs_d/ddd1/Work/Projects/004_Assembly_pipelines/Scripts/Perl/GenerateSEQUELstats.pl"


smrtc=`cat "${path}/${list}" | head -n "${line}" | tail -n 1`


STEP_01:	Extract
#============================================================================================================================================================================================================
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
#	[MULTILINE]
#	samtools view "${path}/${smrtc}.scraps.bam"
#	| cut -f 1,21,22
#	| sed -r 's/s(c|z):A://g'
#	| awk 'BEGIN{}{if($3=="N"){split($1,h,"/|_");printf "%s_%s_%s\t%d\t%d\t%d\t%s\n",h[1],h[2],h[3],h[4],h[5],h[6],$2;}}END{}'
#	> "${path}/processed/preprocessed/TMP.${smrtc}.sc.txt"
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
#	[MULTILINE]
#	samtools view "${path}/${smrtc}.subreads.bam"
#	| cut -f 1
#	| awk 'BEGIN{}{split($1,h,"/|_");printf "%s_%s_%s\t%d\t%d\t%d\tS\n",h[1],h[2],h[3],h[4],h[5],h[6];}END{}'
#	> "${path}/processed/preprocessed/TMP.${smrtc}.sr.txt"
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

samtools view "${path}/${smrtc}.scraps.bam"   | cut -f 1,21,22 | sed -r 's/s(c|z):A://g' | awk 'BEGIN{}{if($3=="N"){split($1,h,"/|_");printf "%s_%s_%s\t%d\t%d\t%d\t%s\n",h[1],h[2],h[3],h[4],h[5],h[6],$2;}}END{}' > "${path}/processed/preprocessed/TMP.${smrtc}.sc.txt"
samtools view "${path}/${smrtc}.subreads.bam" | cut -f 1 | awk 'BEGIN{}{split($1,h,"/|_");printf "%s_%s_%s\t%d\t%d\t%d\tS\n",h[1],h[2],h[3],h[4],h[5],h[6];}END{}' > "${path}/processed/preprocessed/TMP.${smrtc}.sr.txt"

#============================================================================================================================================================================================================



STEP_02:	preprocess
#============================================================================================================================================================================================================
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
#	[MULTILINE]
#	cat
#	"${path}/processed/preprocessed/TMP.${smrtc}.sc.txt"
#	"${path}/processed/preprocessed/TMP.${smrtc}.sr.txt"
#	| sort -k2,2n -k3,3n -k4,4n
#	| awk -f "${preprocess}"
#	> "${path}/processed/preprocessed/${smrtc}.preprocessed"
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

cat "${path}/processed/preprocessed/TMP.${smrtc}.sc.txt" "${path}/processed/preprocessed/TMP.${smrtc}.sr.txt" | sort -k2,2n -k3,3n -k4,4n | awk -f "${preprocess}" > "${path}/processed/preprocessed/${smrtc}.preprocessed"

rm "${path}/processed/preprocessed/TMP.${smrtc}.sc.txt"
rm "${path}/processed/preprocessed/TMP.${smrtc}.sr.txt"

#============================================================================================================================================================================================================



STEP_03:	process
#============================================================================================================================================================================================================
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
#	[MULTILINE]
#	cat "${path}/processed/preprocessed/${smrtc}.preprocessed"
#	| awk 'BEGIN{}{if($3~/[[:digit:]]+H/){print $0 > "/dev/stdout"}else{print $0 > "/dev/stderr"}}END{}'
#	> "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.Hp"
#	2> "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.Hn"
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
#	[MULTILINE]
#	cat "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.Hp"
#	| awk 'BEGIN{}{if($4~/[[:digit:]]+S/){print $0 > "/dev/stdout"}else{print $0 > "/dev/stderr"}}END{}'
#	> "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.HpSp"
#	2> "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.HpSn"
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

cat "${path}/processed/preprocessed/${smrtc}.preprocessed"        | awk 'BEGIN{}{if($3~/[[:digit:]]+H/){print $0 > "/dev/stdout"}else{print $0 > "/dev/stderr"}}END{}' > "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.Hp"   2> "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.Hn"
cat "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.Hp" | awk 'BEGIN{}{if($4~/[[:digit:]]+S/){print $0 > "/dev/stdout"}else{print $0 > "/dev/stderr"}}END{}' > "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.HpSp" 2> "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.HpSn"

rm "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.Hp"

#============================================================================================================================================================================================================



#============================================================================================================================================================================================================

cat "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.Hn"   | awk -f "${process}" > "${path}/processed/per_smrt_cell/Hn/${smrtc}.processed.Hn"
cat "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.HpSn" | awk -f "${process}" > "${path}/processed/per_smrt_cell/HpSn/${smrtc}.processed.HpSn"
cat "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.HpSp" | awk -f "${process}" > "${path}/processed/per_smrt_cell/HpSp/${smrtc}.processed.HpSp"

rm "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.Hn"
rm "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.HpSn"
rm "${path}/processed/preprocessed/TMP.${smrtc}.preprocessed.HpSp"

#============================================================================================================================================================================================================



STEP_04:	Compute stats
#============================================================================================================================================================================================================
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
#	[MULTILINE]
#	perl "${sequelstats}"
#	--Hn "${path}/processed/per_smrt_cell/Hn/${smrtc}.processed.Hn"
#	--HpSn "${path}/processed/per_smrt_cell/HpSn/${smrtc}.processed.HpSn"
#	--HpSp "${path}/processed/per_smrt_cell/HpSp/${smrtc}.processed.HpSp"
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

perl "${sequelstats}" --Hn "${path}/processed/per_smrt_cell/Hn/${smrtc}.processed.Hn" --HpSn "${path}/processed/per_smrt_cell/HpSn/${smrtc}.processed.HpSn" --HpSp "${path}/processed/per_smrt_cell/HpSp/${smrtc}.processed.HpSp"

mv "${path}/processed/per_smrt_cell/Hn/${smrtc}.processed.Hn".*     "${path}/processed/per_smrt_cell/Hn/for_R/"
mv "${path}/processed/per_smrt_cell/HpSn/${smrtc}.processed.HpSn".* "${path}/processed/per_smrt_cell/HpSn/for_R/"
mv "${path}/processed/per_smrt_cell/HpSp/${smrtc}.processed.HpSp".* "${path}/processed/per_smrt_cell/HpSp/for_R/"

#============================================================================================================================================================================================================
