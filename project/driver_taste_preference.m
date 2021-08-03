clear 
clc
format compact 


%---setup---------------------
jID = str2double([getenv('SLURM_JOBID'), getenv('SLURM_ARRAY_TASK_ID')]);
t = 1500; %trial simulation time (s) 
options = set_options(...
    'comp_location','hpc',... %'local' or 'hpc', determines how rng() initializes
    'modeltype','NETS',... %modeltype "NETS" indicates collecting data for example networks 
    'sim_name','nets_D2t-slower_pref',... %the job name
    'jobID',jID,... %numeric ID for job instance
    'tmax',t,... %simulation time (s)
    'netpair_file','D2t-slower',... %specifies set of example networks in heper_functions/get_network_params()
    'noswitch_timeout',t); %timeout without a switch (s) 


%---set the B stimulus B strength, in reference to stimulus A 
stim_mod = [0:.25:2.5,exp(-.5:.5:4),1.3750]; %B = A * stim_mod 
switch options.stim_targs{1}
    case 'Estay' %fast networks will never switch at B > A * 2.5
        stim_mod = stim_mod(stim_mod <= 2.5);
end
stim_mod = randsample(stim_mod,1);
options.trial_stimuli{1}(2) = options.trial_stimuli{1}(2) * stim_mod; %adjust stim B
%show stimulus B value in log file  
update_logfile(sprintf('---stim B set to %.2f Hz (scaled by %.1f)',...
    options.trial_stimuli{1}(2),stim_mod),options.output_log)


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


%------if you need more data for specific networks or something, use code here:
% %---need to get more states for slow nets here, new stim range---
% switch options.stim_targs{1}
%     case 'Estay' %set to random slow network instead
%         slow_nets = 1:2:9;
%         do_config = slow_nets(randi(numel(slow_nets)));
%         options = get_network_params(do_config,options);
% end
% stim_mod = exp(1:.5:3); %new range for stim B
% stim_mod = randsample(stim_mod,1);
% options.trial_stimuli{1}(2) = options.trial_stimuli{1}(2) * stim_mod; %adjust stim B
% %-----------------------------

