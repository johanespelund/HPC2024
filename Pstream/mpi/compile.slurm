#!/bin/bash -l
#SBATCH -J compilePstream
#SBATCH -A edu24.summer
#SBATCH -t 00:05:00
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --output=compile.out


module purge
module load PDC

module load perftools-base
module load perftools
module load openfoam/v2312
source $FOAM_BASHRC

wclean
wmake

