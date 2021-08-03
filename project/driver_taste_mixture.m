clear 
clc
format compact 


%---setup---------------------
jID = str2double([getenv('SLURM_JOBID'), getenv('SLURM_ARRAY_TASK_ID')]);
t = 1500; %trial simulation time (s) 

options = set_options(...
    'comp_location','hpc',... %'local' or 'hpc', determines how rng() initializes
    'modeltype','NETS',... %modeltype "NETS" indicates collecting data for example networks 
    'sim_name','nets_mixstim',... %the job name
    'jobID',jID,... %numeric ID for job instance
    'tmax',t,... %simulation time (s)
    'netpair_file','D2t-slower',... %specifies set of example networks in heper_functions/get_network_params()
    'noswitch_timeout',t); %timeout without a switch (s) 


%---specify the stimulus mixture  
do_nets = 1:10; %you can collect more data for specific nets here, like do_nets =[1,2,5:10];      
options = get_network_params(randsample(do_nets,1),options);
do_totals = [.5,1,2]; %do 50%, 100%, 200% total stimulus intensity 
stim_mod = randsample(do_totals,1); %set total intensity to (stim_mod * A)
%now secify the mixture ratio 
mix_vals = 0:.05:1;
stim_mix = {'Estay','Eswitch'}; %both targets 
p_new = randsample(mix_vals,1); %proportion for (new) alternate stimulus
add_targ = ~strcmp(stim_mix,options.stim_targs{1}); %find the new stimulus targets
options.stim_targs{2} = stim_mix{add_targ};keyboard
total_strength = options.trial_stimuli{1}; %adjust total intensity by stim_mod
total_strength = total_strength .* stim_mod;
options.trial_stimuli{1} = total_strength .* (1-p_new); %"original" stimulus proportion 
options.trial_stimuli{2} = total_strength .* p_new; %new alternate stimulus proportion

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

