#! /bin/sh
#SBATCH --job-name=2M
#SBATCH --output=2M.out
#SBATCH -A edu24.summer
#SBATCH --partition=main
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1

#SBATCH --mail-user=johan.espelund@sintef.no
#SBATCH --mail-type=NONE

## Recommended safety settings:
# set -o errexit # Make bash exit on any error
# set -o nounset # Treat unset variables as errors

# decomp="hierarchical"
decomp="scotch"

# Load modules
module purge
source /opt/cray/pe/cpe/23.12/restore_lmod_system_defaults.sh
module load PDC
module load openfoam/v2312
. $FOAM_BASHRC

echo "Running OpenFOAM case $SLURM_JOB_NAME on $SLURM_NTASKS cores"
echo "Job ID:" $SLURM_JOB_ID
echo "Job started at" `date`
echo "Job is running on node(s):" `hostname`
echo "Job running in directory:" `pwd`
echo "SLURM assigned me the nodes:" $SLURM_NODELIST
echo "SLURM assigned me the cores:" $SLURM_NTASKS
echo "SLURM variables:" $SLURM_JOB_NODELIST

echo "SLURM_NTASKS_PER_NODE: $SLURM_NTASKS_PER_NODE"
echo "SLURM_NTASKS: $SLURM_NTASKS"
echo "SLURM_MEM_PER_CPU: $SLURM_MEM_PER_CPU"

WM_PROJECT_USER_DIR=$PWD

rm -r processor*
rm -rf postProcessing
foamListTimes -rm

if [ ! -d "constant/polyMesh" ]; then
  blockMesh > log.blockMesh
  checkMesh > log.checkMesh
fi


sed -i "s/n_processors.*/n_processors $SLURM_NTASKS;/g" parameters
sed -i "s/decomp.*/decomp $decomp;/g" parameters
cp ../decomposeParDict$SLURM_NTASKS system/decomposeParDict
foamListTimes -rm
rm -rf processor*
rm -rf postProcessing

# Create a unique directory to store the run outputs
UNIQUE_RUN_DIR="N${SLURM_NTASKS}-${decomp}-${timeCase}"
mkdir -p $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR

# Print system information into hardware.info file inside the unique directory
echo "Job running on node: $(hostname)" > $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/hardware.info
echo "Total CPUs allocated: $SLURM_CPUS_ON_NODE" >> $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/hardware.info
echo "Allocated nodes: $SLURM_NODELIST" >> $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/hardware.info
echo "Memory details:" >> $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/hardware.info
free -h >> $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/hardware.info
echo "CPU details:" >> $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/hardware.info
lscpu >> $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/hardware.info
numactl --show >> $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/hardware.info
scontrol -dd show job $SLURM_JOB_ID >> $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/hardware.info

if [ "$SLURM_NTASKS" -eq "1" ]; then
  echo "Running serial case."
  starttime=$(date +"%H.%M.%S")
  echo "Simulation started at:" `date`
  t0=$(date +"%s")
  buoyantPimpleFoam > log_${SLURM_NTASKS} 2>log.error
  t1=$(date +"%s")
  runtime=$((t1-t0))
  endtime=$(date +"%H.%M.%S")
else
  echo "Running paralell case."
  if [ ! -d "processor0" ]; then
    decomposePar > log.decomposePar$SLURM_NTASKS$decomp
  fi

  # Set the number of nodes based on the number of tasks
  if [ "$SLURM_NTASKS" -le 128 ]; then
    num_nodes=1
  else
    num_nodes=2
  fi

  echo "Simulation started at:" `date`
  starttime=$(date +"%H.%M.%S")
  t0=$(date +"%s")
  srun -n $SLURM_NTASKS buoyantPimpleFoam -parallel > log_${SLURM_NTASKS} 2>log.error
  t1=$(date +"%s")
  runtime=$((t1-t0))
  endtime=$(date +"%H.%M.%S")
fi

# Extract the last ClockTime from the log file
last_clock_time=$(grep "ClockTime" log_${SLURM_NTASKS} | tail -1 | awk '{print $(NF-1)}')

echo "${SLURM_NTASKS},${SLURM_JOB_NAME},${SLURM_NNODES},${SLURM_JOB_ID},${runtime},${last_clock_time},PCG-DIC,${decomp},${timeCase}" >> ../weak_scaling.dat

echo "Simulation ended at:" `date`

cp log.error log_${SLURM_NTASKS} log.decomposePar${SLURM_NTASKS}$decomp 2M.out  $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR/

echo "Run completed. Logs and output stored in $SLURM_SUBMIT_DIR/$UNIQUE_RUN_DIR"


