clear
clc
format compact
hold off;close all

%This file runs a few short simulations and plots the results with inspect.m
%I used this code to first get some "nice looking" example data for
%plotting the network characteristics figure (figure 1 in the results).
%Once I had some nice looking data, I ran figs4net_characteristics.m

addpath('../')
Sname = 'example_behavior_revisions';

jobs = 74:10:574; %do a few runs for slow net #2
tmax = 35;

for idx = 1:numel(jobs)
    
    %---setup---------------------
    options = set_options('modeltype','diagnostics','comp_location','local',...
        'sim_name',Sname,'jobID', jobs(idx),'tmax',tmax,'netpair_file','D2t-slower',...
        'noswitch_timeout',tmax+1);
    
    do_net = mod(options.jobID,10);
    do_net(do_net == 0) = 10;
    options = get_network_params(do_net,options);
    options.EtoE = .0405; %fixed
    %keep stimulus 
    %options.trial_stimuli{1} = [0,0]; %no stimulus
    options.trial_stimuli{1} = options.trial_stimuli{1} * 0.6;
    
    run_this_job(Sname,options)
    
    fprintf('job finished (JID = %i)\n',options.jobID)
    
end




function run_this_job(Sname,opt)
%---run-----------------------
exit_status = false;
while ~exit_status
    [modelfile,exit_status] = diag_model(opt);
end
%---cleanup-------------------
driverfile = mfilename;
backup_jobcode(opt,driverfile,modelfile)
delete(opt.output_log) %no need for these right now

setenv('JID',num2str(opt.jobID));
setenv('SIM_NAME',Sname);
inspect
hold off;close all
end
