# pflacco Experiment:
This GitHub project contains the current state of pflacco as well as the experimental code which is used in paper:
(p)flacco: Exploratory Landscape Analysis of Single-Objective Continuous Black-Box Problems in R and Python

## Prerequisites
For a stable (and tested) outcome, this experiment requires at least [Python>=3.8.6](https://www.python.org/downloads/release/python-386/)

## Setup
All required packages in their exact versions are referenced in the requirements.txt
These should be installed in a seperate virtual environment via the following series of commands (assuming Mac/Linux OS):
```bash
python3 -m venv ven
source venv/bin/activate
python3 -m pip install -r requirements.txt
```

## Quickstart
The experiments descriped in the paper were conducted sequentially.
Meaning the python file starting with a "0_generate_job_scripts.py" was used to generate the several instances/jobs of "1_calculate_features_template.py. These were computed on a High-Performance-Cluster. After completion, the second script "2_feature_selection.py" was executed and analysed on a personal computer with "3_fs_analysis.R". 

To recreate for instance the calculation of ELA features for the BBOB Function 1 with Instance 1 and dimension 5, you can simply run the following command:
```bash
python3 1_calculate_features_template.py 1 5 1
```

The code of the SFFS feature selection can be found in "2_feature_selection.py" and does not require any additonal arguments, i.e., 
```bash
python3 2_feature_selection.py
```

## Contact
I endorse and appreciate every comment. Feel free to contact me under raphael.prager@uni-muenster.de
