#!/bin/bash -l
#SBATCH -J compile
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

export PAT_RT_SUMMARY=0
export LD_LIBRARY_PATH=$FOAM_USER_LIBBIN:$LD_LIBRARY_PATH

wclean
wmake

ldd $(which myBuoyantPimpleFoam) | grep Pstream

mv $FOAM_USER_APPBIN/myBuoyantPimpleFoam .
cp Make/linux64*/myBuoyantPimpleFoam.o .

# Comment out following line after running the +apa build

pat_build -O apa $FOAM_USER_APPBIN/tracingBuoyantPimpleFoam
mv tracingBuoyantPimpleFoam+apa $FOAM_USER_APPBIN/

# Uncmment the folloing line to build the +pat version with the options
# obtained from the +apa run.

# pat_build -O ../tank/tracingBuoyantPimpleFoam+pat+4108228-2045314329s/build-options.apa
# mv tracingBuoyantPimpleFoam+pat $FOAM_USER_APPBIN/

