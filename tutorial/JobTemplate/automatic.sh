#!/bin/bash

# Prepare input data container
echo "YES" | ../utils/create_data_container.sh inputdata /mnt 50
# Copies all data files into the inputdata folder
cp ../data/* /mnt/inputdata/							
# Verifies data has been copied
ls /mnt/inputdata/								

# Verifies data has been copied
../utils/umount_data_container.sh inputdata /mnt				
scp inputdata.img hnolte1@transfer-scc.gwdg.de:/scratch/users/hnolte1/secure

# Secure-copies inputdata.img onto hpc server
scp inputdata.img sachut@transfer-scc.gwdg.de:/scratch/users/sachut/secure	

# Prepare output container
echo "YES" | ../utils/create_data_container.sh outdata /mnt 500			
# Unmounts
../utils/umount_data_container.sh outdata /mnt					

# Copies outdata.img onto hpc server
scp outdata.img sachut@transfer-scc.gwdg.de:/scratch/users/<hpc-uid>/secure	

# Prepares command.sh, copies generated default and wrapped tokens into it
# Sends keys to vaults
./prepare_scripts.sh

# Creates command.sh.asc, recipient is slurm 
../utils/encrypt_script.sh command.sh <pubKeyOfServer>

cat command.sh.asc

# Removes preexisting run.sh
rm run.sh

# Prepares run.sh file 
echo "#!/bin/bash" > run.sh
echo "/usr/bin/decrypt_and_execute <<EOF" >> run.sh
cat command.sh.asc >> run.sh
echo -n "EOF" >> run.sh

cat run.sh

# Creates detached signature for run.sh
gpg --detach-sign --local-user <LocalUserKey> -o run.sh.sig run.sh

# Secure copies run.sh, run.sh.sig onto scratch 
scp run.sh run.sh.sig <hpc-uid>@<hpc-frontend>:/scratch/users/sachut/home/

# Executes run.sh on secure client
slurmid=$(ssh <hpc-uid>@<hpc-frontend> 'cd /scratch/users/sachut/home/ ; /opt/slurm/bin/sbatch -p secure -G 1 --time=2-00:00:00 -n 16 --mem=40G run.sh' | gawk '{print $4}')

while [[ $(ssh <hpc-uid>@<hpc-frontend> "/opt/slurm/bin/sacct -b -j $slurmid | gawk '{print $2}' | awk 'FNR > 2' | grep -v COMPLETED") != "" ]] ; do echo "Waiting for job to end!" ; sleep 10 ; done

echo 'finished'

# Copies image file from server to local 
scp <hpc-uid>@<hpc-frontend>:/scratch/users/sachut/secure/outdata.img .

# Mounts outdata
../utils/mount_data.sh outdata
