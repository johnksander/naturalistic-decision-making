clear
clc
format compact
hold off;close all
%investigating model behavior

%This driver shows an example diagnostics run looking at network behavior
%during the stimulus mixture simulations. 

addpath('../') %set_options() lives in the main project directory 
jobID = 2; %numeric ID for job instance
Sname = 'mixstim_test'; %the job name

%---setup---------------------
tmax = 25;
options = set_options(...
    'comp_location','local',... %'local' or 'hpc', determines how rng() initializes
    'modeltype','diagnostics',... %modeltype "diagnostics" indicates this is a project/diagnostics job 
    'sim_name',Sname,... %the job name
    'jobID',jobID,... %numeric ID for job instance
    'tmax',tmax,... %simulation time (s)
    'netpair_file','D2t-slower',... %specifies set of example networks in heper_functions/get_network_params()
    'noswitch_timeout',tmax); %timeout without a switch (s) 


%---setting up the job to mimic driver_taste_preference.m 
do_net = 2;
options = get_network_params(do_net,options);
options.EtoE = .0405; %fixed
%both stims are now mixed ratio 
stim_mix = {'Estay','Eswitch'}; %both targets 
p_new = .2; %proportion alternate (new) stimulus
add_targ = ~strcmp(stim_mix,options.stim_targs{1});
options.stim_targs{2} = stim_mix{add_targ};
total_strength = options.trial_stimuli{1};
options.trial_stimuli{1} = total_strength .* (1-p_new);
options.trial_stimuli{2} = total_strength .* p_new;


%---run-----------------------
exit_status = false;
while ~exit_status
    [modelfile,exit_status] = diag_model(options); %note diag_model() not spikeout_model()
end
%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(options,driverfile,modelfile)
delete(options.output_log) %no need for these right now

%---plot network behavior-------------------
setenv('JID',num2str(jobID)) %inspect.m will look for these variables 
setenv('SIM_NAME',Sname); 

inspect %run inspect.m on results generated from this simulation 









