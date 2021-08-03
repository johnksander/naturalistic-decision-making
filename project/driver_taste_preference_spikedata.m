clear
clc
format compact


%---setup---------------------
jID = str2double([getenv('SLURM_JOBID'), getenv('SLURM_ARRAY_TASK_ID')]);
t = 75; %trial simulation time (s)
options = set_options(...
    'comp_location','hpc',... %'local' or 'hpc', determines how rng() initializes
    'modeltype','NETS',... %modeltype "NETS" indicates collecting data for example networks
    'sim_name','nets_D2t-slower_spikedata',... %the job name
    'jobID',jID,... %numeric ID for job instance
    'tmax',t,... %simulation time (s)
    'netpair_file','D2t-slower',... %specifies set of example networks in heper_functions/get_network_params()
    'noswitch_timeout',t,... %timeout without a switch (s)
    'record_spiking','on'); %record spikes during leave decisions ('on' decreases performance)



%---run-----------------------
modelfile = spikeout_model(options);
%---cleanup-------------------
if isempty(dir(fullfile(options.save_dir,'code4*zip')))
    driverfile = mfilename;
    backup_jobcode(options,driverfile,'spikeout_model.m')
end
delete(options.output_log) %no need for these right now
% logdir = fullfile(options.save_dir,'logs'); %put them seperately
% if ~isdir(logdir),mkdir(logdir);end
%movefile(options.output_log,logdir)

