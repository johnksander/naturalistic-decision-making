clear
clc
format compact

%---setup---------------------
jID = str2double([getenv('SLURM_JOBID'), getenv('SLURM_ARRAY_TASK_ID')]);
t = 1500; %trial simulation time (s)

options = set_options(...
    'comp_location','hpc',... %'local' or 'hpc', determines how rng() initializes
    'modeltype','NETS',... %modeltype "NETS" indicates collecting data for example networks 
    'sim_name','nets_mixstim-NOBSTEST-THR01',... %the job name
    'jobID',jID,... %numeric ID for job instance
    'tmax',t,... %simulation time (s)
    'netpair_file','D2t-slower',... %specifies set of example networks in heper_functions/get_network_params()
    'noswitch_timeout',t,... %timeout without a switch (s) 
    'no_dominance_timeout',t,... %timeout if neither or both pools active > X seconds
    'state_test_thresh',.01); %difference in mean Sg between E-cell pools

%---notes:
% (1) This collects data without the pool dominance test ('no_dominance_timeout' = t)
% and with a lower difference threshold for determining the active state
% ('state_test_thresh' = .01, default is .02). 
%
% (2) This driver also collects data for specific networks and stimulus
% parameters (see below). 
%
% (3) This driver fills in data for supplementary figures 3 & 4, where the
% network and stimulus parameters give bistable activity--- but with lower
% difference between pool activities. This was tripping bistability tests
% in the regular simulation code and aborting jobs. Data collected here is
% shown in supplementary figures 3 and 4 as dotted lines. 



%---Run networks without bistability test, and with lower switch threshhold.
%-nly collecting data for some specific parameterizations lacking data... 
do_nets = [6:8,10]; %networks that need data
do_nets = randsample(do_nets,1);
options = get_network_params(do_nets,options);

%stimulus parameters for each network that needs data 
if do_nets == 7 
    stim_mod = .5;
else
    stim_mod = 2;
end

if do_nets == 7
    mix_vals = .2:.05:1;
elseif do_nets == 6
    mix_vals = 0:.05:.3;
elseif do_nets == 8
    mix_vals = 0:.05:.6;
elseif do_nets == 10
    mix_vals = 0:.05:.6;
end

%set stimulus to mixed ratio
stim_mix = {'Estay','Eswitch'}; %both targets
p_new = randsample(mix_vals,1); %proportion alternate (new) stimulus
add_targ = ~strcmp(stim_mix,options.stim_targs{1});
options.stim_targs{2} = stim_mix{add_targ};
total_strength = options.trial_stimuli{1};
total_strength = total_strength .* stim_mod;
options.trial_stimuli{1} = total_strength .* (1-p_new);
options.trial_stimuli{2} = total_strength .* p_new;
%add stimulus info to the log file 
msg = sprintf('---stimuli mixed as %i/%i',round((1-p_new)*100),round(p_new*100));
update_logfile(msg,options.output_log)
for idx = 1:numel(options.stim_targs)
    msg = sprintf('---\t %.2f Hz -> %s',options.trial_stimuli{idx}(1),options.stim_targs{idx});
    update_logfile(msg,options.output_log)
end

%---checkpoint file information, spikeout_model_grid() will generate and use this same filename  
options.grid_index = str2double(getenv('SLURM_ARRAY_TASK_ID'));%HPCC only lets indicies up to 10k!!
checkpointFN = fullfile(options.save_dir,sprintf('checkpoint_%i.mat',options.grid_index));

%---to only resume unfinished jobs, uncomment next three lines 
%if exist(checkpointFN) == 0 %only run unfinished jobs 
%    delete(options.output_log);return
%end

%---run-----------------------
modelfile = spikeout_model_grid(options);
%---cleanup-------------------
if isempty(dir(fullfile(options.save_dir,'code4*zip')))
    driverfile = mfilename;
    backup_jobcode(options,driverfile,'spikeout_model.m')
end
delete(checkpointFN)
update_logfile('checkpoint data deleted',options.output_log)
%delete(options.output_log) %no need for these right now
logdir = fullfile(options.save_dir,'logs'); %put them seperately
if ~isdir(logdir),mkdir(logdir);end
movefile(options.output_log,logdir)

