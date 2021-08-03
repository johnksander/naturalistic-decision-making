clear
clc
format compact
hold off;close all

%This file runs a few short simulations and plots the results with inspect.m
%I used this code to first get some "nice looking" example data for
%plotting the network characteristics figure (figure 1 in the results).
%Once I had some nice looking data, I ran figs4net_characteristics.m

addpath('../')

%jobs = 14:10:44; %do a few runs for slow net #2
jobs = 1:10; %one of each pleasse
tmax = 25;

cross_conns = [1, 2.5, 5];

for Cidx = 1:numel(cross_conns)
    
    Xconn = cross_conns(Cidx); %cross-connection strength (relative to E-to-E) 
    
    Sname = sprintf('new_circuit_test_x%i',Xconn*100);
    
    
    for idx = 1:numel(jobs)
        
        %---setup---------------------
        options = set_options('modeltype','diagnostics','comp_location','local',...
            'sim_name',Sname,'jobID', jobs(idx),'tmax',tmax,'netpair_file','D2t-slower',...
            'noswitch_timeout',tmax+1,'cut_leave_state',tmax,...
            'conn_scheme','reviews');
        
        do_net = mod(options.jobID,10);
        do_net(do_net == 0) = 10;
        options = get_network_params(do_net,options);
        options.EtoE = .0405; %fixed
        options.trial_stimuli{1} = [0,0]; %no stimulus
        
        switch options.conn_scheme
            case 'reviews'
                %this specifies the connection strengths for new connections added for reviews
                recurrent_str = options.EtoE; %self-connection strength for E-to-E
                cross_str = Xconn * recurrent_str; %new cross connections strengths
                options.ItoI = recurrent_str; %match E-to-E
                options.ItoI_cross = cross_str;
                options.EtoE_cross = cross_str;
        end
        
        run_this_job(Sname,options)
        
        fprintf('job finished (JID = %i)\n',options.jobID)
        
    end
    
end
% %do a regular one for comparison
% Sname = 'original_circuit';
% for idx = 1:numel(jobs)
%     
%     %---setup---------------------
%     options = set_options('modeltype','diagnostics','comp_location','local',...
%         'sim_name',Sname,'jobID', jobs(idx),'tmax',tmax,'netpair_file','D2t-slower',...
%         'noswitch_timeout',tmax+1,'cut_leave_state',tmax,...
%         'conn_scheme','orginal');
%     
%     do_net = mod(options.jobID,10);
%     do_net(do_net == 0) = 10;
%     options = get_network_params(do_net,options);
%     options.EtoE = .0405; %fixed
%     options.trial_stimuli{1} = [0,0]; %no stimulus
%     
%     switch options.conn_scheme
%         case 'reviews'
%             %this specifies the connection strengths for new connections added for reviews
%             recurrent_str = options.EtoE; %self-connection strength for E-to-E
%             cross_str = .25 * recurrent_str; %new cross connections strengths
%             options.ItoI = recurrent_str; %match E-to-E
%             options.ItoI_cross = cross_str;
%             options.EtoE_cross = cross_str;
%     end
%     
%     run_this_job(Sname,options)
%     
%     fprintf('job finished (JID = %i)\n',options.jobID)
%     
% end


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
