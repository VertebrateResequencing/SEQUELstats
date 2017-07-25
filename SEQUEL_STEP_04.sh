#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#	CHECK IMPORTED VARIABLES
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

SCRIPT_Name="$(basename $0)"

if [[ -z "${SPIPE_dpath:+x}" ]] ; then echo -e "\n[${SCRIPT_Name}]:\t\"SPIPE_dpath\" not set!\n" ; exit 1 ; fi
if [[ -z "${SPIPE_smrtc+x}"  ]] ; then echo -e "\n[${SCRIPT_Name}]:\t\"SPIPE_smrtc\" not set!\n" ; exit 2 ; fi
if [[ -z "${SPIPE_pro:+x}"   ]] ; then echo -e "\n[${SCRIPT_Name}]:\t\"SPIPE_pro\" not set!\n"   ; exit 3 ; fi
if [[ -z "${SPIPE_sta:+x}"   ]] ; then echo -e "\n[${SCRIPT_Name}]:\t\"SPIPE_sta\" not set!\n"   ; exit 4 ; fi
if [[ -z "${SPIPE_step:+x}"  ]] ; then echo -e "\n[${SCRIPT_Name}]:\t\"SPIPE_step\" not set!\n"  ; exit 5 ; fi

if [[ -z "${SEQUEL_stats:+x}"  ]] ; then echo -e "\n[${SCRIPT_Name}]:\t\"SEQUEL_stats\" not set!\n"  ; exit 6 ; fi

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#	INITIALISE VARIABLES
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

SEQL_block="${SPIPE_dpath}/${SPIPE_step}.RUNNING.${SPIPE_smrtc}"	# This file acts as a kind of "road block": while it exists the next step cannot start!

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
#	RUN
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

echo "Starting '${SPIPE_step}' ..." > "${SEQL_block}"

#- Check the "processed" files for each subset as they could be empty depending on the data
for i in "Hn" "HpSn" "HpSp" ;
do
	if ! [[ -e "${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.${i}" ]] || ! [[ -s "${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.${i}" ]] ; then
		echo -e "\n[${SCRIPT_Name}]:\t\"${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.${i}\" does not exist or is empty!\n"
		exit 7
	fi
done
#-


########################################################################################################################################################################################
# Line-wrapped command :
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
#	perl "${SEQUEL_stats}"
#	--Hn   "${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.Hn"
#	--HpSn "${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.HpSn"
#	--HpSp "${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.HpSp"
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
########################################################################################################################################################################################

perl "${SEQUEL_stats}" --Hn "${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.Hn" --HpSn "${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.HpSn" --HpSp "${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.HpSp"


chk=$?	# get 'awk' exit code

if [[ "${chk}" -ne 0 ]] ; then
	echo -e "\n[${SCRIPT_Name}]:\t${SEQUEL_stats} terminated with exit code \"${chk}\"!\n"
	exit 8
else
	for i in "Hn" "HpSn" "HpSp" ;
	do
		mkdir "${SPIPE_sta}/${i}"
		
		for j in "aCnt" "hist" "lFlg" "stats" ;
		do
			SEQL_osfile="${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.${i}.${j}"	# Stat file generated from processed input file
			SEQL_nsfile="${SPIPE_sta}/${i}/${SPIPE_smrtc}.${i}.${j}"	# New location and name for the file
			
			if [[ -e "${SEQL_osfile}" ]] ; then
				if [[ -s "${SEQL_osfile}" ]] ; then
					mv "${SEQL_osfile}" "${SEQL_nsfile}"
					
					
					chk=$?	# get 'mv' exit code
					
					if [[ "${chk}" -ne 0 ]] ; then
						echo -e "\n[${SCRIPT_Name}]:\tError moving \"${SEQL_osfile}\", exit code \"${chk}\"!\n"
						exit 10
					else
						rm "${SPIPE_pro}/PRO.${SPIPE_smrtc}.txt.${i}"	# Remove processed input file (not needed anymore once the stats are done)
					fi
				else
					echo -e "\n[${SCRIPT_Name}]:\t\"${SEQL_osfile}\" is empty, check input file!\n"
					exit 9
				fi
			fi
		done
	done
fi	

rm "${SEQL_block}"

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
