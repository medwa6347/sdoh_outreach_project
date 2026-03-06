#!/usr/bin/ksh
#######################################################################################
# Author:  M.W. Kirksey, with edits by Michael Edwards
# Date  :  12/09/2019
# Descrp:  0001_xo_sdoh_shell.ksh - execute SAS on HPA
#
########################################	AMDG  #######################################
#
#######################################################################################

#######################################################################################
# Script debugging option.  Uncomment for debug mode.
#######################################################################################
# set -x   # Uncomment to debug this shell script (Korn shell only)

#######################################################################################
# Assign
# - client
# - script
# - production source code directory (d)
# - project root directory (p)
# - iteration ID (i)
# - Email Address (eml) - In case of job/step failure or job conclusion
#######################################################################################
client=xo-merck-sdogh
script=0001_xo_sdoh_shell.ksh
d=/sasnas/ls_cs_nas/mwe/xo/merck_sdoh_202008/amdg
p=/sasnas/ls_cs_nas/mwe/xo/merck_sdoh_202008/amdg
i=p114
eml=$( grep -oP "(?<=').*(?=')" /sasnas/ls_cs_nas/mwe/zz_common/00_common/00_email.txt )

#######################################################################################
# Step 01:  Run 0002_sdoh_data_intake_and_reporting.sas
#
#           - Datetime stamp (dt) - Attach to log and report name
#           - Specify program (pgm) name (without .sas) at each step
#           - Specify step code (scode) reference
#
#           sas <SAS Source code folder/<sas program>.sas
#           -AUTOEXEC <SAS Source code folder/<sas program>.sas
#           -SYSPARM = Parameter string 
#           -LOG = SAS Logs folder
#           -PRINT = SAS LST folder
#           -MEMSIZE = Memorary allocation
#           -F = Run job in foreground.  Need to do to capture RC, properly
#           -GRIDJOBNAME = Assign a unique job name to the job
#
#######################################################################################
dt=$(date +'%Y%m%d.%H.%M.%S')
pgm=0003_sdoh_data_intake_cohorts
scode=03
sas_tws ${d}/${pgm}.sas \
    -autoexec ${p}/00_common/00_common.sas \
    -sysparm ${i} \
    -log ${p}/00_loglst/keep/p111_14/${pgm}_${i}_${dt}.log \
    -print ${p}/00_loglst/keep/p111_14/${pgm}_${i}_${dt}.lst \
    -memsize 2G \
    -f \
    -GRIDJOBNAME ${script:0:7}_${scode}

rc=$?
if (( ${rc} == 1 )) then
  rc=0  ## Allow for SAS Warnings
elif (( ${rc} == 47 )) then
  rc=0  ## Log/Report copy delay
fi
echo ${scode}' - Preliminary RC='${rc}

if (( ${rc} != 0 )) then
  echo 'Current Step:  '${scode}
  echo 'Error in Step.  Error Code='${rc}
  echo "${script} - Job Failure:  Step "${scode} | mailx -s "$client - ${script}" "${eml}"
  exit ${scode}  ## Use current step as exit code
fi

#######################################################################################
# Write Success message, if the job had no errors
#######################################################################################
echo "Job ${script} completed successfully!"
echo "${client} - ${script} / Job Completed!" | mailx -s "$client - ${script}" "${eml}"

#######################################################################################
# End of Script.
#######################################################################################