#!/usr/bin/env bash


sbatch --array=1-400 parsweep_reviews_paulcompute.sh
sbatch --array=401-2800 parsweep_reviews.sh

#this is for running jobs that collect only the slow datapoints 
#like, valid_range = ItoE >= 7.5 & EtoI >= .225
