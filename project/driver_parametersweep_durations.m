clear 
clc
format compact 

%---setup---------------------
jID = str2double([getenv('SLURM_JOBID'), getenv('SLURM_ARRAY_TASK_ID')]);
t = 1500; %trial simulation time (s) 
options = set_options(...
    'comp_location','hpc',... %'local' or 'hpc', determines how rng() initializes
    'modeltype','PS',... %modeltype is PS for "parsweep"
    'sim_name','parsweep_D2t_very_slow_baseline',... %the job name
    'jobID',jID,... %numeric ID for job instance
    'tmax',t,... %simulation time (s)
    'ratelim_check','off',... %check for plausible spikerates ('on' decreases performance)
    'cut_leave_state',t,... %after Xms in a leave state, half noise E-switch cells 
    'noswitch_timeout',t); %timeout without a switch (s) 

%---note:
%we set cut_leave_state = tmax here because there's no stimulus and we're 
%measure both the "stay" and "leave" state durations (there's no difference, double the data)

%---grid search
Ngrid = 100;
ItoE = linspace(0.1,12.5,Ngrid);
EtoI = linspace(0,.75,Ngrid);
[ItoE,EtoI] = meshgrid(ItoE,EtoI);
ItoE = ItoE(:); EtoI = EtoI(:);
%---if looking only for slow networks, uncomment next three lines 
%valid_range = ItoE >= 7.5 & EtoI >= .225;
%ItoE = ItoE(valid_range);
%EtoI = EtoI(valid_range);
options.grid_index = str2double(getenv('SLURM_ARRAY_TASK_ID'));%HPCC only lets indicies up to 10k!!
options.ItoE = ItoE(options.grid_index);
options.EtoI = EtoI(options.grid_index);

%---checkpoint file information, spikeout_model_grid() will generate and use this same filename 
checkpointFN = fullfile(options.save_dir,sprintf('checkpoint_%i.mat',options.grid_index)); 

%---to only resume unfinished jobs, uncomment next three lines 
% if exist(checkpointFN) == 0 %only run unfinished jobs 
%     delete(options.output_log);return
% end

%---run-----------------------
modelfile = spikeout_model_grid(options);
%---cleanup-------------------
if isempty(dir(fullfile(options.save_dir,'code4*zip')))
    driverfile = mfilename;
    backup_jobcode(options,driverfile,modelfile)
end
delete(checkpointFN)
update_logfile('checkpoint data deleted',options.output_log)
logdir = fullfile(options.save_dir,'logs'); %put them seperately
if ~isdir(logdir),mkdir(logdir);end
movefile(options.output_log,logdir)