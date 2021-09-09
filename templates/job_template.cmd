#!/bin/bash

# set the number of nodes
#SBATCH --nodes=1

# set the number of CPU cores per node
#SBATCH --ntasks-per-node=1

# How much memory is needed (per node)
#SBATCH --mem=30GB

# set max wallclock time
#SBATCH --time=02:00:00

# set name of job
#SBATCH --job-name=PLACEHOLDER_JOB_NAME

# mail alert at start, end and abortion of execution
#SBATCH --mail-type=END

# send mail to this address
#SBATCH --mail-user=raphael.prager@uni-muenster.de

# run the application
python3 /home/r/r_prag01/pflacco_experiment/1_calculate_features_template.py PLACEHOLDER_ARGS
