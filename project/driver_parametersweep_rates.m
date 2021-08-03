clear 
clc
format compact 

%---setup---------------------
jID = str2double(getenv('SLURM_ARRAY_TASK_ID')); %used for indexing files below 
t = 25; %trial simulation time (s) 
sim_name = 'parsweep_D2t-slower_spikerates'; %var needed again below 
options = set_options(...
    'comp_location','hpc',... %'local' or 'hpc', determines how rng() initializes
    'modeltype','PS',... %modeltype is PS for "parsweep"
    'sim_name',sim_name,... %the job name
    'jobID',jID,... %numeric ID for job instance
    'tmax',t,... %after Xms in a leave state, half noise E-switch cells 
    'ratelim_check','on',... %check for plausible spikerates ('on' decreases performance)
    'noswitch_timeout',t+1,... %timeout without a switch (s) 
    'cut_leave_state',t); %timeout without a switch (s) 

%---notes:
% (1) we set cut_leave_state = tmax here because there's no stimulus and we're 
% measure both the "stay" and "leave" state durations (there's no difference, double the data)
%
% (2) this driver uses the spikeout_model_rateonly() simulation code. This
% file only differs from spikeout_model() in that state durations are not
% considered, only spikerates are measured. 
%
% (3) we set noswitch_timeout = tmax + 1 so that jobs may complete without ever
% registering a state transition. We're only concerned with measuring
% spikerates here, so that's fine. 
%
% (4) driver loads some predefined parameter files (code immediately below).
% I did this to run only the parameters with data from parametersweep_durations_driver.m 
% these files were prepared with inspect_results/parsweep/extras/file_task.m


%files should already be here
FN = dir(fullfile(options.save_dir,'*mat'));
FN = {FN.name};
FN = FN{jID};
FN = fullfile(options.save_dir,FN);

conn_params = load(FN);
conn_params = conn_params.options;
options.EtoI = conn_params.EtoI;
options.ItoE = conn_params.ItoE;
options.jobID = conn_params.jobID; %VERY IMPORTANT
options.sim_name = sprintf('PS_%s_%i',sim_name,options.jobID); 

%---run-----------------------
run_job = true;
while run_job

    modelfile = spikeout_model_rateonly(options);
    results = load(FN);
    if isfield(results,'sim_results')
        results = results.sim_results;
        results = results(4); %should be where ratelim is 
        run_job = isempty(results); %stop running if you've got rate data 
    end
end


%---cleanup-------------------
if isempty(dir(fullfile(options.save_dir,'code4*zip')))
    driverfile = mfilename;
    backup_jobcode(options,driverfile,modelfile)
end
delete(options.output_log) %no need for these right now
% logdir = fullfile(options.save_dir,'logs'); %put them seperately
% if ~isdir(logdir),mkdir(logdir);end
% movefile(options.output_log,logdir)