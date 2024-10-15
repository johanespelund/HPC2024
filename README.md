# HPC2024

Repository for storing setup for performance analysis of *buoyantPimpleFoam* using _perftools_.
Part of the PDC Summer School 2024.

## Compilation and instrumentation
First the Pstream library must be recompiled. Navigate to the folder `Pstream/mpi/` and submit `compile.slurm`.

Then navigate to `tracingBuoyantPimpleFoam/` and submit `compile.slurm`.
This will create an executable `tracingBuoyantPimpleFoam+apa`. 
Run a testcase using this executable, using only a few time steps. 
This will create an output on the `.apa` format. Follow the instructions in `compile.slurm`
and use this as the input configuration file for `pat_build` to build the final instrumented executable,
`tracingBuoyantPimpleFoam+pat`.
