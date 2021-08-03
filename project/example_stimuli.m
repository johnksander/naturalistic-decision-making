clear
clc
format compact


%The way I've set up stimulus specification here is less than ideal. I've
%included some examples and a little function here to make it clearer and
%easier.

%The function in this file takes a more plainly formatted table and puts
%that information into the options stimulus structure format. There's some
%examples here.

%::::::::   example 1   ::::::::
%stimulus A is 50 Hz -> E-stay & 100 Hz -> E-switch
%stimulus B is 100 Hz -> E-stay & 50 Hz -> E-switch

stim_labels = {'A','B'}; %fixed, varied
cell_pools = {'Estay','Eswitch','Istay','Iswitch'};
varnames = ['label',cell_pools];

stimuli = array2table(NaN(numel(stim_labels),numel(varnames)),'VariableNames',varnames);
stimuli.label = stim_labels';
stimuli.Istay = zeros(2,1);
stimuli.Iswitch = zeros(2,1);
stimuli.Estay = [50;100];
stimuli.Eswitch = [100;50];

fprintf('::::::::   example 1   ::::::::\n\n\n')

disp(stimuli);fprintf('\n') %table show the example

options = table2options(stimuli); %how this goes into the options structure format

disp(options);fprintf('\n\n')

%::::::::   example 2   :::::::: this is like the taste preference simulations
%stimulus A is 50 Hz -> E-stay 
%stimulus B is 100 Hz -> E-stay 

stimuli.Estay = [50;100];
stimuli.Eswitch = zeros(2,1);

fprintf('::::::::   example 2   ::::::::\n\n')
fprintf('(this is like the taste preference simulations)\n\n\n')

disp(stimuli);fprintf('\n') %table show the example

options = table2options(stimuli); %how this goes into the options structure format

disp(options);fprintf('\n\n')

%::::::::   example 3   :::::::: this is like the stimulus mixture simulations
%stimulus A is 50 Hz -> E-stay & 100 Hz -> E-switch
%stimulus B is 50 Hz -> E-stay & 100 Hz -> E-switch

stimuli.Estay = [50;100];
stimuli.Eswitch = [50;100];

fprintf('::::::::   example 3   ::::::::\n\n')
fprintf('(this is like the stimulus mixture simulations)\n\n\n')

disp(stimuli);fprintf('\n') %table show the example

options = table2options(stimuli); %how this goes into the options structure format

disp(options);fprintf('\n\n')




function options = table2options(table_fmt)

stim_labels = {'A','B'}; %fixed, varied
cell_pools = {'Estay','Eswitch','Istay','Iswitch'};

targets = table_fmt{:,cell_pools}; %how many non-zero target pools
targets = sum(targets) > 0;
target_labels = cell_pools(targets);
N = sum(targets);
T = numel(stim_labels); %number of trials always 2
options.stim_targs = cell(1,N);
options.trial_stimuli = cell(1,N);

for n = 1:N
    curr_target = target_labels{n};
    trial_stims = NaN(1,T);
    for t = 1:T
        curr_trial = strcmp(stim_labels{t},table_fmt.label);
        trial_stims(t) = table_fmt{curr_trial,curr_target};
    end
    options.stim_targs{n} = target_labels{n};
    options.trial_stimuli{n} = trial_stims;
end

end

