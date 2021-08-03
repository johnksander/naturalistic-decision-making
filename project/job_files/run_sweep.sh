#!/usr/bin/env bash


sbatch --array=1-1000 parsweep_reviews_paulcompute.sh
sbatch --array=1001-6000 parsweep_reviews.sh
sbatch --array=6001-6500 parsweep_reviews_paulcompute.sh
sbatch --array=6501-10000 parsweep_reviews.sh

#do like, 20% paul-compute and 80% guest 
