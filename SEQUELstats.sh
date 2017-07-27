#==========================================================================================================================================================================================================================================#
#	CONFIGURATION :
#==========================================================================================================================================================================================================================================#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#	SOFTWARE PATHS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
SEQUEL_RSCRIPT="/software/bin/Rscript"

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#	PIPELINE PATHS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
SEQUEL_STATS_path="/nfs/users/nfs_d/ddd1/Work/Projects/004_Assembly_pipelines/Scripts/Shell/SEQUELstats"

SEQUEL_pipe="${SEQUEL_STATS_path}/SEQUEL_pipe.sh"
SEQUEL_plot="${SEQUEL_STATS_path}/SEQUEL_plot.R"

declare -a SPIPE_STEPS=("STEP_01" "STEP_02" "STEP_03" "STEP_04")

#==========================================================================================================================================================================================================================================#



#==========================================================================================================================================================================================================================================#
#	COMMAND-LINE PARAMETER
#==========================================================================================================================================================================================================================================#

SCRIPT_Name="$(basename $0)"

if [[ -z "${1:+x}" ]] ; then echo -e "\n[${SCRIPT_Name}]:\tNo \"subreads\" BAM FOFN specified!\n" ; exit 1 ; fi
if [[ -z "${2:+x}" ]] ; then echo -e "\n[${SCRIPT_Name}]:\tNo \"scraps\" BAM FOFN specified!\n"   ; exit 2 ; fi
if [[ -z "${3:+x}" ]] ; then echo -e "\n[${SCRIPT_Name}]:\tNo output directory specified!\n"      ; exit 3 ; fi
if [[ -z "${4:+x}" ]] ; then echo -e "\n[${SCRIPT_Name}]:\tNo sample name specified!\n"           ; exit 4 ; fi

SEQL_srfofn="${1}"	# "Subreads" BAM FOFN
SEQL_scfofn="${2}"	# "Scraps"   BAM FOFN
SEQL_dpath="${3}"	# Output path
SEQL_sname="${4}"	# Sample name e.g. "fAnaTes1"

SEQL_dpath=`echo "${SEQL_dpath}" | sed -r 's/\/+$//'`

if ! [[ -e "${SEQL_srfofn}" ]] ; then echo -e "\n[${SCRIPT_Name}]:\t\"subreads\" BAM FOFN does not exist!\n" ; exit 5 ; fi
if ! [[ -e "${SEQL_scfofn}" ]] ; then echo -e "\n[${SCRIPT_Name}]:\t\"scraps\" BAM FOFN does not exist!\n"   ; exit 6 ; fi

#==========================================================================================================================================================================================================================================#



#==========================================================================================================================================================================================================================================#
#	PIPELINE PREPARATION
#==========================================================================================================================================================================================================================================#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#	INITIALISE VARIABLES
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
SEQL_srfs=`cat "${SEQL_srfofn}" | wc -l`	# Count number of files in "subread" FOFN
SEQL_scfs=`cat "${SEQL_scfofn}" | wc -l`	# Count number of files in "scraps"  FOFN

if [[ "${SEQL_srfs}" -ne "${SEQL_scfs}" ]] ; then echo -e "\n[${SCRIPT_Name}]:\tNumber of \"subreads\" and \"scraps\" files does not match!\n" ; exit 7 ; fi

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#	GENERATE PIPELINE FOLDER STRUCTURE
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
SEQL_out="${SEQL_dpath}/out"
SEQL_err="${SEQL_dpath}/err"
SEQL_sta="${SEQL_dpath}/stats"

mkdir -p "${SEQL_dpath}"

mkdir -p "${SEQL_out}"
mkdir -p "${SEQL_err}"
mkdir -p "${SEQL_sta}/Hn" "${SEQL_sta}/HpSn" "${SEQL_sta}/HpSp"

#==========================================================================================================================================================================================================================================#



#==========================================================================================================================================================================================================================================#
#	RUN
#==========================================================================================================================================================================================================================================#

for i in `seq 0 3` ;
do
	SEQL_step="${SPIPE_STEPS[${i}]}"
	
	SEQL_done="${SEQL_dpath}/${SEQL_step}.DONE"
	SEQL_block="${SEQL_dpath}/${SEQL_step}.RUNNING"
	
	########################################################################################################################################################################################
	# Line-wrapped command :
	#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	#
	#	bsub
	#	-Ep "echo \"Done\" > \"${SEQL_done}.\$LSB_JOBINDEX\""
	#	-q normal
	#	-R "select[type==X86_64 && mem > 8192] rusage[mem=8192]" -M 8192
	#	-J "SEQSTATS_${SEQL_step}[1-${SEQL_srfs}]%${SEQL_srfs}"
	#	-o "${SEQL_out}/${SEQL_step}.%I.out"
	#	-e "${SEQL_err}/${SEQL_step}.%I.err"
	#	"
	#	\"${SEQUEL_pipe}\"
	#	\"${SEQL_srfofn}\"
	#	\"${SEQL_scfofn}\"
	#	\"${SEQL_dpath}\"
	#	\$LSB_JOBINDEX
	#	\"${SEQL_step}\"
	#	"
	#
	########################################################################################################################################################################################
	
	bsub -Ep "echo \"Done\" > \"${SEQL_done}.\$LSB_JOBINDEX\"" -q normal -R "select[type==X86_64 && mem > 8192] rusage[mem=8192]" -M 8192 -J "SEQSTATS_${SEQL_step}[1-${SEQL_srfs}]%${SEQL_srfs}" -o "${SEQL_out}/${SEQL_step}.%I.out" -e "${SEQL_err}/${SEQL_step}.%I.err" "\"${SEQUEL_pipe}\" \"${SEQL_srfofn}\" \"${SEQL_scfofn}\" \"${SEQL_dpath}\" \$LSB_JOBINDEX \"${SEQL_step}\""
	
	
	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
	#	CHECKS, PROCESSING & CLEANUP
	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
		
		failed=4
		
		#- Wait for all SMRTcell jobs to finish
		while ! [[ -e "${SEQL_done}".1 ]] || [[ `ls "${SEQL_done}".* | wc -l` -ne "${SEQL_srfs}" ]] ; do sleep 60s; done
		#-
		
		sleep 60s
		
		#- Check whether all jobs finished successfully
		if [[ `ls "${SEQL_dpath}"/*.* | grep -Ec "^${SEQL_block}\..+$"` -eq 0 ]]                               ; then (( --failed )); fi	# Check for "road block" files
		if [[ `ls "${SEQL_out}"/*.* | grep -Ec "${SEQL_step}\.[[:digit:]]+\.out"` -eq "${SEQL_srfs}" ]]        ; then (( --failed )); fi	# Count "out" files
		if [[ `ls "${SEQL_err}"/*.* | grep -Ec "${SEQL_step}\.[[:digit:]]+\.err"` -eq "${SEQL_srfs}" ]]        ; then (( --failed )); fi	# Count "err" files
		if [[ `cat "${SEQL_out}/${SEQL_step}."*.out | grep -Fc "Successfully completed"` -eq "${SEQL_srfs}" ]] ; then (( --failed )); fi	# Check "out" files
		#-
		
		#- If so ...
		if [[ "${failed}" -eq 0 ]] ; then
			rm "${SEQL_done}".*
			
			#-- Archive LSF "*.out" files
			cd "${SEQL_out}"
			tar -czf "${SEQL_step}.OUT.tar.gz" "${SEQL_step}".*.out
			if [[ -e "${SEQL_step}.OUT.tar.gz" ]] && [[ -s "${SEQL_step}.OUT.tar.gz" ]] ; then rm "${SEQL_step}".*.out; fi
			#--
			
			#-- Archive LSF "*.err" files
			cd "${SEQL_err}"
			tar -czf "${SEQL_step}.ERR.tar.gz" "${SEQL_step}".*.err
			if [[ -e "${SEQL_step}.ERR.tar.gz" ]] && [[ -s "${SEQL_step}.ERR.tar.gz" ]] ; then rm "${SEQL_step}".*.err; fi
			#--
		else
			echo -e "\n[${SCRIPT_Name}]:\t${SPIPE_STEPS[${i}]} failed, pipeline terminated!\n"
			exit 8
		fi
		#-
		
	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
done

#============================================================================================================================================================================================================



#==========================================================================================================================================================================================================================================#
#	PLOT
#==========================================================================================================================================================================================================================================#

#- Move data from invidual folders per SMRTcell into one folder per type (i.e. Hn/HpSn/HpSp)
mv "${SEQL_dpath}/"*"/stats/Hn/"*.*   "${SEQL_sta}/Hn"
mv "${SEQL_dpath}/"*"/stats/HpSn/"*.* "${SEQL_sta}/HpSn"
mv "${SEQL_dpath}/"*"/stats/HpSp/"*.* "${SEQL_sta}/HpSp"
#-

"${SEQUEL_RSCRIPT}" "${SEQUEL_plot}" "${SEQL_sta}" "${SEQL_sname}"

#==========================================================================================================================================================================================================================================#
