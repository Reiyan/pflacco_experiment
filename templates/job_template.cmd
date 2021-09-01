#!/bin/bash

# set the number of nodes
#SBATCH --nodes=1

# set the number of CPU cores per node
#SBATCH --exclusive

# How much memory is needed (per node)
#SBATCH --mem=160GB

# set max wallclock time
#SBATCH --time=08:00:00

# set name of job
#SBATCH --job-name=PLACEHOLDER_JOB_NAME

# mail alert at start, end and abortion of execution
#SBATCH --mail-type=ALL

# send mail to this address
#SBATCH --mail-user=r_prag01@uni-muenster.de

# run the application
mpirun -n 72 python /home/r/r_prag01/acma_es/main.py PLACEHOLDER_ARGS
