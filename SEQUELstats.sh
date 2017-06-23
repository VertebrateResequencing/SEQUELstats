path="${1}"
list="${2}"

pshpsc="/nfs/users/nfs_d/ddd1/Work/Projects/004_Assembly_pipelines/Scripts/Shell/process_sequel_headers_per_smrt_cell.sh"


mkdir -p "${path}/processed/out"
mkdir -p "${path}/processed/err"
mkdir -p "${path}/processed/preprocessed"

mkdir -p "${path}/processed/per_smrt_cell/Hn/for_R"
mkdir -p "${path}/processed/per_smrt_cell/HpSn/for_R"
mkdir -p "${path}/processed/per_smrt_cell/HpSp/for_R"


runs=`cat "${path}/${list}" | wc -l`


#============================================================================================================================================================================================================
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
#	[MULTILINE]
#	bsub
#	-Ep "echo \"Done\" > ${path}/processed/PSHPSC.DONE.\$LSB_JOBINDEX"
#	-q normal
#	-R "select[type==X86_64 && mem > 8192] rusage[mem=8192]" -M 8192
#	-J "PSHPSC[1-${runs}]%${runs}"
#	-o "${path}/processed/out/process.%I.out"
#	-e "${path}/processed/err/process.%I.err"
#	"
#	${pshpsc} ${path} ${list} \$LSB_JOBINDEX
#	"
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

bsub -Ep "echo \"Done\" > ${path}/processed/PSHPSC.DONE.\$LSB_JOBINDEX" -q normal -R "select[type==X86_64 && mem > 8192] rusage[mem=8192]" -M 8192 -J "PSHPSC[1-${runs}]%${runs}" -o "${path}/processed/out/process.%I.out" -e "${path}/processed/err/process.%I.err" "${pshpsc} ${path} ${list} \$LSB_JOBINDEX"

#============================================================================================================================================================================================================


while [[ `ls "${path}/processed" | grep -Fc "PSHPSC.DONE"` -ne "${runs}" ]] ; do sleep 60s; done

rm "${path}/processed/PSHPSC.DONE".*


cat "${path}/processed/per_smrt_cell/Hn/"*.Hn     > "${path}/processed/ALL.Hn"
cat "${path}/processed/per_smrt_cell/HpSn/"*.HpSn > "${path}/processed/ALL.HpSn"
cat "${path}/processed/per_smrt_cell/HpSp/"*.HpSp > "${path}/processed/ALL.HpSp"
