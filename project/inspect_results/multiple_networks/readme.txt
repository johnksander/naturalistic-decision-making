info about the files in inspect_results/multiple_networks/

file_tasks/ contains a few scripts I used for processing different results (removing bad files, etc). 

get_stimOpt_results.sh sorts through results from the stimulus equating job (see the main readme) 

the files: stimulus_mixed.m, stimulus_mixed_example_figure.m, stimulus_preference.m, and stimulus_preference_spikedata.m all process and plot results from the task simulations (see main readme) 


mixstim_followup_analysis/ contains the files mixstim_analysis.m and mixstim_analysis_followup.m. I used these files to figure out how the sampling times differed as a function of mixture difference vs mixture ratio. 

mixstim_vals.m plots the stimulus ratio/difference combinations (figure used in manuscript). 

get_percentile() and sim_spikerate() are helper functions called me these scripts. 

