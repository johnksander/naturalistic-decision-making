## Code and manuscript materials for Naturalistic Decision Making project

The manuscript/ directory contains all text, reference (endnote) files, figures and
figure-making files (e.g. powerpoint files used for creating final figures). The
subdirectories split the manuscript by section, and should be fairly self explanatory.

The project/ directory contains the code for this project. This readme describes
the code and it's usage in detail.

-----------------------------
### Table of contents

1)   Code in the project/ main directory  
2)   The project/Results directory  
3)   The project/helper_functions directory  
4)   The project/job_files directory  
5)   The project/inspect_results directory  
6)   The project/diagnostics directory and network characteristic figures  
7)   Parameter sweep  
8)   Equating stimuli  
9)   Taste preference task  
10)  Stimulus mixture task  
11)  Stimulus data structure  

-----------------------------
### 1. Code in the main project/ directory  

1) driver files  

   The main directory contains "driver files" for the various simulations in this project. A driver file specifies the simulation parameters, runs the simulation, then backs up all the relevant job code.

2) set_options.m  

   The set_options.m file contains an arg parser (I made this before matlab had one of those), parameter defaults, and some set-up/configuration stuff. This is the primary file for specifying parameters and simulation details relevant to different parts of the project.

3) the spikeout_model files

   The spikeout_model.m actually runs the model simulations and contains probably the most critical code. The other two model files (spikeout_model_grid.m & spikeout_model_rateonly.m) only differ slightly.

   The spikeout_model_grid.m saves incremental checkpoints during simulation run and can resume aborted simulations from those files.

   The spikeout_model_rateonly.m file does not include code for saving and recording state durations, but measures pool activities during active states. This code was intended for running short simulations just to record spikerates. This file does not include code for recording state durations because that code involves various checks that conflict with running such jobs (i.e. ensuring there's at least one stay-state following the first stay-state, etc).

### 2.   The project/Results directory  

   All jobs save raw data into project/Results/XXX where XXX is the job name (options.sim_name). Within this directory, the driver file saves all relevant code to a zip file titled code4XXX.zip (where XXX is the job name, with a job ID sometimes). This zip file preserves a record of all the code used to generate the raw data in that directory.


   Code that processes raw data or generates figures will create a new directory project/Results/figures_XXX and save the summary datafiles and figures there (again, XXX is the job name).

### 3.   The project/helper_functions directory  

   This directory contains code for a variety of smaller tasks. A great many of these files are long depreciated and are not used anywhere. There's a lot of files in here and I didn't get around to cleaning out the old ones.

### 4.   The project/job_files directory  

   This contains all the SLURM sbatch files for different simulations. They don't contain the job array information (because I often reran with different array sizes, etc), so the generally you would submit these like:  

   sbatch --array=1-10000 spikedata.sh

### 5.   The project/inspect_results directory  

   This directory has code for processing and plotting the saved data in project/Results.  

   A general note: code that generates figures (e.g. code in inspect_results/multiple_networks/) also process the raw data. If the data has not been processed before, this will invoke a parfor loop set to 24 workers (and probably eat a lot of memory). For jobs that have already been plotted once, these files will simply load a summary results file (no parfor/data processing).

### 6.   The project/diagnostics directory and network characteristic figures  

1) code in project/diagnostics  

   Code in the project/diagnostics directory runs simulations that save all relevant data (e.g. entire variable timecourses). These jobs require sufficient memory and save very large files in projects/Results. There's also code for plotting this data. Collectively, these scripts are for examining what's going on during simulations in more detail.

   diag_model() is the same as spikeout_model(), except diag_model() stores and saves variable timecourse data. The file driver_example.m shows an example workflow in projects/diagnostics.

   1) driver file specifies simulation and runs diag_model()  
   2) inspect.m plots the saved results  

2) network characteristics figures  

   The files show_net_behavior.m and figs4net_characteristics.m generate the network behavior plots in results figure 4.

   The file figs4net_characteristics.m generates the spikerate plots used in results figure 3 (showing equated network sampling times).

### 7.   Parameter sweep  

1) data collection

   driver files for collecting the data:  

   driver_parametersweep_durations.m  
   driver_parametersweep_rates.m  

   You can collect both spikerate and duration data simultaneously (it's actually much better that way) by simply specifying 'ratelim_check', 'on' in the durations driver file. However, I collected the duration and spikerate data separately.  

   These drivers were made for running on the cluster as array jobs  

   sbatch --array=1-10000 job_files/parsweep.sh  
   sbatch --array=1-10000 job_files/parsweep_rates.sh  

2) data processing and plotting

   1) code for processing & plotting the data

      inspect_results/parsweep/parsweep_results.m  

      Processes the array job results and plots result figure 2 panels A, C, and D.  

   2) code for picking example networks

      inspect_results/parsweep/parsweep_find_examples.m  

      Pulls this processed data and picks the example networks. This code will plot figure 2 panel B, and then save example network parameters to project/helper_functions/network_pairs/  

      For plotting without messing with the existing parameter files, specify these options at the beginning of parsweep_find_examples.m  

      save_netfile = 'no'; %yes/no (saves the example parameters into a mat file, used by other functions)  
      load_netfile = 'yes'; %'yes' loads existing examples (for plotting), 'no' finds new examples  
      save_figs = 'yes';  

3) adding example network parameters to the toolbox

   In project/helper_functions/network_pairs/ you can use print_params() to generate switch statement code. This code then goes in helper_functions/get_network_params.m  

   The switch code in get_network_params() supplies the example network parameters for all subsequent simulations.  

### 8.   Equating stimuli  

The driver file driver_equate_durations.m finds the stimuli needed to produce the same average state durations in all networks (i.e. 7.5s). You must run this driver on the cluster, preferably on paul-compute with 3 days walltime (the maximum). You only submit this driver as a single task like:

sbatch job_files/optim_stim.sh

However! Make sure you include --array=1-1 (this is in optim_stim.sh sbatch file) or the rng() seeding will fail (requires array index for seed calculation).

The optimization job will print results to log files in /Results/equate_D2t-slower_stims

in /inspect_results/inspect_stimeq/ the files get_stimOpt_results.sh and look_at_data.m will help format the results. In particular, get_stimOpt_results.sh will show the best stimulus values found by the optimizer. Those stimulus values should be added to the corresponding networks in helper_functions/get_network_params() (the stimulus values go in   Rstim = X)

### 9.   Taste preference task  


1) data collection

   the driver file driver_taste_preference.m collects the taste preference behavioral data. These drivers were made for running on the cluster as array jobs

   sbatch --array=1-10000 job_files/taste_pref.sh

2) data processing and plotting  

   figures 5, 6 and supplementary figures 5 & 6 are generated in inspect_results/multiple_networks/stimulus_preference.m


3) data collection (spiking activity)

   the driver file driver_taste_preference_spikedata.m collects spiking data during leave decisions. These drivers were made for running on the cluster as array jobs  

   sbatch --array=1-10000 job_files/spikedata.sh  

4) data processing and plotting (spiking activity)

   figure 8 and supplementary figure 5 (the spiking activity during leave decisions) are generated in inspect_results/multiple_networks/stimulus_preference_spikedata.m  

### 10.  Stimulus mixture task  


1) data collection

   the driver file is driver_taste_mixture.m, this will collect sampling durations for mixed hedonic/aversive stimuli. These drivers were made for running on the cluster as array jobs  


   sbatch --array=1-10000 job_files/mix_stim.sh  


   Please note: the way I've set up stimulus specification in these driver files is weird. The example_stimuli.m file gives a good example and some code for setting up stimulus parameters (including a function for converting plainly formatted tables into the options stimulus structure)  

2) low threshold jobs

   For some networks and stimulus mixtures, the activity difference states (active & inactive) sometimes dips lower than the threshold. The driver file driver_taste_mixture_LOWTHR.m gathers data for these parameterizations with lower thresholding and without bistability checks. This data was plotted as dotted lines in supplementary figures 3 and 4.  


3) processing and plotting data

   in inspect_results/multiple_networks/ the stimulus_mixed.m file processes simulation data and generates supplementary figures 3 and 4. After running stimulus_mixed.m, you can generate figure 7 with stimulus_mixed_example_figure.m.  

4) adding low threshold data to figures

   Finally, stimulus_mixed_plot_lowthrdata.m in inspect_results/multiple_networks/ adds the low threshold simulation data to supplementary figures 3 and 4 as dotted lines.  

5) plotting task stimulus values

   mixstim_vals.m in inspect_results/multiple_networks/ generates figure 3 in the methods (plots the mixture ratios and intensities).  

### 11.  Stimulus data structure  

1) description

   Please see example_stimuli.m for code demonstrating how stimuli are specified for spikeout_model(). That code contains examples and a function for converting plainly formatted table information into the stimulus options structure used in these simulations.  

   This section also contains more detailed information below.  

   The stimulus information is given to spikeout_model() though the options structure input. Within spikeout_model(), the options structure is again passed to init_stimvar() where the stimulus information is converted into the stim_info structure. THat stim_info structure is ultimately used during the simulation (as input for  timepoint_stimulus() ).  

   The stimulus information is primarily specified by two fields in options: options.trial_stimuli and options.stim_targs. Both fields are cell arrays.  

2) options.stim_targs

   options.stim_targs is a 1 x N cell array, where N is the number of cell pools receiving input (... N = 1 if only E-stay gets input, N = 2 if both E-stay and E-switch get input, etc).  

   Each cell contains a string specifying the target pool, either 'Estay','Eswitch','Istay' or 'Iswitch'.  

3) options.trial_stimuli  

   options.trial_stimuli is also a 1 X N cell array (same size as options.stim_targs)

   Each cell contains a 1 x 2 vector. This vector specifies the stimulus intensity (in Hz) for stimulus A and stimulus B. Each cell always contains a 1 x 2 vector, even in simulations with only one stimulus (e.g. the stimulus mixture simulations).
