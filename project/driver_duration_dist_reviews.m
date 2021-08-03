clear 
clc
format compact 

%---setup---------------------
jID = str2double([getenv('SLURM_JOBID'), getenv('SLURM_ARRAY_TASK_ID')]);
t = 750; %trial simulation time (s) 
options = set_options(...
    'comp_location','hpc',... %'local' or 'hpc', determines how rng() initializes
    'modeltype','NETS',... %modeltype "NETS" indicates collecting data for example networks 
    'sim_name','nets_distribution_long_review',... %the job name
    'jobID',jID,... %numeric ID for job instance
    'tmax',t,... %simulation time (s)
    'netpair_file','D2t-slower',... %specifies set of example networks in heper_functions/get_network_params()
    'ratelim_check','off',... %check for plausible spikerates ('on' decreases performance)
    'cut_leave_state',t,... %after Xms in a leave state, half noise E-switch cells 
    'noswitch_timeout',t); %timeout without a switch (s) 

%---note:
%we set cut_leave_state = tmax here because there's no stimulus and we're 
%measure both the "stay" and "leave" state durations (there's no difference, double the data)

%-----set network params-----
do_config = 3; % do fast net #2 
options.EtoE = .0405; %fixed
%pull ItoE, EtoI, Rstim, and stim cell targets for network ID
options = get_network_params(do_config,options);

options.trial_stimuli{1} = [0,0]; %no stimulus

%now say it again
update_logfile(sprintf('---EtoE = %.3f',options.EtoE),options.output_log)
update_logfile(sprintf('---ItoE = %.3f',options.ItoE),options.output_log)
update_logfile(sprintf('---EtoI = %.3f',options.EtoI),options.output_log)
if isfield(options,'trial_stimuli')
    for idx = 1:numel(options.trial_stimuli)
        update_logfile(sprintf('---trial stimuli = %.1f Hz, %.1f Hz',options.trial_stimuli{idx}),options.output_log)
    end
end
if isfield(options,'stim_targs')
    for idx = 1:numel(options.stim_targs)
        update_logfile(sprintf('---target cells = %s',options.stim_targs{idx}),options.output_log)
    end
end
update_logfile('--------------------------',options.output_log)


%---run-----------------------
modelfile = spikeout_model(options);
%---cleanup-------------------
if isempty(dir(fullfile(options.save_dir,'code4*zip')))
    driverfile = mfilename;
    backup_jobcode(options,driverfile,modelfile)
end

% savename = fullfile(options.save_dir,options.sim_name);
% data = load(savename);
% state_durations = data.sim_results;
% state_durations = state_durations{1};
% %state.count recorded in second col
% state_durations = state_durations(:,2);
% state_durations = cat(1,state_durations{:});
% %convert to time
% state_durations = state_durations * options.timestep;
% 
% %plot
% fz = 20;
% 
% histogram(state_durations)
% set(gca,'FontSize',fz)
% ylabel('frequency','FontWeight','bold')
% xlabel('duration (s)','FontWeight','bold')
% set(gca,'box','off')
% print('state_duration_distribution','-djpeg','-r600')
