clear;clc
format compact
hold off;close all


%---this plots upplementary figures 3 and 4, processes data for figure 7.
%Run stimulus_mixed_example_figure.m to generate figure 7 after the data
%has been processed here.

basedir = '~/Desktop/rotation/project'; %project directory!
addpath(fullfile(basedir,'helper_functions'))

opt = struct();
opt.min_obs = 250; %min # of observations (states)
opt.print_anything = 'yes'; %'yes' | 'no';
opt.outcome_stat = 'logmu';  %'mu' | 'med' | 'logmu'
opt.Xax = 'diff'; %'diff' or 'ratio'


%process data for both the the main stimulus mixture simulations, and then
%the lower-threshold simulations. Figures will print to the fiddir
%directiory in project/Results/
Snames = {'nets_mixstim','nets_mixstim-NOBSTEST-THR01'};
figdir = cellfun(@(x) sprintf('figures_%s',x),Snames,'UniformOutput',false);

for idx = 1:numel(Snames)
    opt.Xax = 'diff'; %stimulus difference figure
    make_my_figs(basedir,Snames{idx},figdir{idx},opt)
    opt.Xax = 'ratio'; %stimulus ratio figure
    make_my_figs(basedir,Snames{idx},figdir{idx},opt)
end




function make_my_figs(basedir,sim_name,figdir,opt)
hold off;close all
opt.multiple_stimuli = 'yes'; %always yes...
opt.params2match = {'conn'}; %!!!IMPORTANT!!! specify how results are matched to network types
opt.parfor_load = 'on'; %on/off, must also (un)comment the actual for... line
opt.pulse_stim = 'off'; %'yes' | 'total_time' | 'rem' | 'off' whether to treat durations as samples (rem = time during sample)
opt.valid_states = 'stay'; %'stay' | 'all'; undecided is always invalid, 'all' gives stay & leave
outcome_stat = opt.outcome_stat;
pulse_stim = opt.pulse_stim;
print_anything = opt.print_anything; %'yes' | 'no';
summary_stats = 'no'; %summary_stats = opt.summary_stats;
params2match = opt.params2match;
figdir = fullfile(basedir,'Results',figdir,'durations');
resdir = fullfile(basedir,'Results',sim_name);
%output_fns = dir(fullfile(resdir,['*',sim_name,'*.mat'])); %use this for unrestricted loading
warning('LOADING ALL MAT FILES IN RESULTS DIR (checkpoint.mat files, etc will probably break this')
output_fns = dir(fullfile(resdir,'*.mat')); %use this for unrestricted loading
output_fns = cellfun(@(x,y) fullfile(x,y),{output_fns.folder},{output_fns.name},'UniformOutput',false);
BL_fns = dir(fullfile([resdir '_baseline'],['*',sim_name,'*.mat']));
BL_fns = cellfun(@(x,y) fullfile(x,y),{BL_fns.folder},{BL_fns.name},'UniformOutput',false);
output_fns = cat(2,BL_fns,output_fns);
%checking for previously saved data
svdir = fullfile(figdir,'data');if ~isdir(svdir),mkdir(svdir);end
svFN = [sim_name '_%s.mat'];
switch pulse_stim
    case 'yes'
        svFN = sprintf(svFN,'total_samples');
    case 'rem'
        svFN = sprintf(svFN,'decision_timing');
    otherwise
        svFN = sprintf(svFN,'total_time');
end
if exist(fullfile(svdir,svFN)) > 0,load_summary = true;else,load_summary = false;end

switch opt.multiple_stimuli
    case 'yes'
        param_varnams = {'ItoE','EtoI','stim_A','stim_B','targ_cells'};
        %line below may be important
        %IDvars = param_varnams(~ismember(param_varnams,'stim_B')); %stim B not particular to network type
    case 'no'
        param_varnams = {'ItoE','EtoI','stim','targ_cells'};
end
%for indexing the result paramters
IDvars = [];
if sum(strcmp('conn',params2match)) > 0,IDvars = {'ItoE','EtoI'};end
if sum(strcmp('stim',params2match)) > 0,IDvars = [IDvars,param_varnams(startsWith(param_varnams,'stim'))];end

IDvars = IDvars(~ismember(IDvars,'stim_B')); %stim B not particular to network type

%get general options file from the first file
gen_options = load(output_fns{1});
gen_options = gen_options.options;
gen_options = rmfield(gen_options,{'stim_targs','trial_stimuli'});
timestep = gen_options.timestep;

switch pulse_stim
    case 'off'
        %skip this business
    otherwise
        %pulse duration... kinda hardcoded here
        error('get this from  options dude, was previously striped from sim name')
end

num_files = numel(output_fns);
stimtarg_vals = {'baseline','Estay','Eswitch'}; %this is dumb
stimtarg_labels = {'baseline','fast','slow'};

%info on the specific network parameters in this simulation
num_net_types = 10;
num_pairs = 5;
pair_inds = num2cell(reshape(1:num_net_types,[],num_pairs)); %just gives a cell array for pair indicies
network_pair_info = cell(num_pairs,1);
for idx = 1:num_pairs
    curr_params = cellfun(@(x) get_network_params(x,gen_options),pair_inds(:,idx),'UniformOutput',false);
    switch opt.multiple_stimuli
        case 'yes'
            curr_params = cellfun(@(x)...
                [x.ItoE, x.EtoI,num2cell(x.trial_stimuli{:}),x.stim_targs],...
                curr_params,'UniformOutput',false); %matching "network_pair_info" format
        otherwise
            curr_params = cellfun(@(x)...
                {x.ItoE, x.EtoI,unique(x.trial_stimuli), x.stim_targs},...
                curr_params,'UniformOutput',false); %matching "network_pair_info" format
    end
    curr_params = cat(1,curr_params{:});
    T = cell2table(curr_params,'VariableNames',param_varnams);
    curr_types = T.targ_cells;
    curr_types = strrep(curr_types,'Estay','fast'); curr_types = strrep(curr_types,'Eswitch','slow');
    T.Properties.RowNames = curr_types;
    network_pair_info{idx} = T;
end

warning('find_pref_durations() will be needed for undecided states')


fprintf('\n---loading simulation: %s\n',sim_name)

if ~load_summary
    %get results
    switch opt.parfor_load
        case 'off'
            fprintf('\nparfor disabled\n')
        case 'on'
            num_workers = 24;
            c = parcluster('local');
            c.NumWorkers = num_workers;
            parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',{which('find_stay_durations')})
            special_progress_tracker = fullfile(basedir,'SPT.txt');
            if exist(special_progress_tracker) > 0, delete(special_progress_tracker);end %fresh start
    end
    switch opt.valid_states %select states for analysis
        case 'all'
            warning('\nfind_stay_durations() disabled, all non-undecided states')
    end
    
    %warning('\ntrimming all data from events starting T < 20 s')
    
    file_data = cell(num_files,2);
    parfor idx = 1:num_files
        %for idx = 1:num_files
        switch opt.parfor_load
            case 'off'
                if mod(idx,500) == 0,fprintf('working on file #%i/%i...\n',idx,num_files);end
        end
        curr_file = load(output_fns{idx});
        %get state durations
        state_durations = curr_file.sim_results;
        state_durations = state_durations{1};
        switch opt.valid_states %select states for analysis
            case 'all'
                %just get all of them, baseline test. Everything that's not undecided
                keep_states = ~strcmpi(state_durations(:,end),'undecided');
                %state.count recorded in second col
                state_durations = state_durations(keep_states,2);
                state_durations = cat(1,state_durations{:});
                %convert to time
                state_durations = state_durations * timestep;
            case 'stay'
                [state_durations,Sinfo] = find_stay_durations(state_durations,curr_file.options,'verify');
                
                %                 %limiting events to T > 20 s
                %                 too_early = cell2mat(Sinfo.event_time) - state_durations.duration; %start time
                %                 too_early = too_early < 20; %20 second limit
                %                 state_durations = state_durations(~too_early,:);
                %                 Sinfo = Sinfo(~too_early,:);
                
                switch pulse_stim
                    case 'yes' %just do this now while options is handy
                        state_durations = state_durations.samples;
                    case 'rem' %look at when IN the sample switch happened
                        state_durations = state_durations.decision_time;
                    case 'total_time'
                        state_durations = state_durations.duration;
                    case 'off'
                        state_durations = state_durations.duration;
                end
                state_durations = [array2table(state_durations,'VariableNames',{'data'}),Sinfo(:,'state')];
        end
        
        %store durations & parameters
        file_data(idx,:) = {state_durations,curr_file.options};
        
        switch opt.parfor_load
            case 'on'
                progress = worker_progress_tracker(special_progress_tracker);
                if mod(progress,floor(num_files * .05)) == 0 %at half a percent
                    progress = (progress / num_files) * 100;
                    fprintf('%s ---- %.1f percent complete\n',datestr(now,31),progress);
                end
        end
    end
    switch opt.parfor_load
        case 'on'
            delete(gcp('nocreate'))
            delete(special_progress_tracker)
    end
    
    %save a big results file
    data_sz = whos('file_data');
    data_sz = data_sz.bytes / 1e9; %in GB
    if data_sz > 5
        fprintf('\nWARNING: summary file size = %.2f GB\n... summary file will not be saved\n',data_sz)
    else
        fprintf('\nsaving data...\n')
        save(fullfile(svdir,svFN),'file_data','-v7.3')
        fprintf('complete\n')
    end
    
    
elseif load_summary
    fprintf('\nloading saved summary data...\n')
    file_data = load(fullfile(svdir,svFN));
    file_data = file_data.file_data;
end

%search for jobs with identical parameters, collapse distributions
%get the randomized network parameters

switch opt.multiple_stimuli
    case 'yes'
        %         job_params = cellfun(@(x)...
        %             [x.ItoE, x.EtoI,x.trial_stimuli,find(strcmpi(x.stim_targs, stimtarg_vals))],...
        %             file_data(:,2),'UniformOutput',false); %matching "network_pair_info" format
        
        %         job_params = cellfun(@(x)...
        %             [x.ItoE, x.EtoI,cat(2,x.trial_stimuli{:}),...
        %             cellfun(@(xx) find(strcmp(xx,stimtarg_vals)),x.stim_targs)],...
        %             file_data(:,2),'UniformOutput',false); %matching "network_pair_info" format
        
        job_params = cellfun(@(x)...
            [x.ItoE, x.EtoI,cat(2,x.trial_stimuli{:}),...
            cellfun(@(xx) find(strcmp(xx,stimtarg_vals)),x.stim_targs)],...
            file_data(:,2),'UniformOutput',false); %matching "network_pair_info" format
    otherwise
        job_params = cellfun(@(x)...
            [x.ItoE, x.EtoI,unique(x.trial_stimuli),find(strcmpi(x.stim_targs, stimtarg_vals))],...
            file_data(:,2),'UniformOutput',false); %matching "network_pair_info" format
end

job_params = vertcat(job_params{:});
uniq_params = unique(job_params,'rows');
%net_type = array2table(uniq_params,'VariableNames',param_varnams);
num_jobs = size(uniq_params,1);
fprintf('----------------------\n')
fprintf('num jobs = %i\nunique parameter sets = %i\nduplicates = %i\n',num_files,num_jobs,num_files - num_jobs)

%collapse duplicate job parameters
result_data = cell(num_jobs,2);
Nruns = NaN(num_jobs,1); %record the number of successful jobs..
for idx = 1:num_jobs
    %find all matching
    curr_file = ismember(job_params,uniq_params(idx,:),'rows');
    Nruns(idx) = sum(curr_file);
    %explain_params = net_type(idx,:);
    %explain_params.targ_cells = stimtarg_vals{explain_params.targ_cells};
    %fprintf('\n---parameter set\n');disp(explain_params);fprintf('n files = %i\n',Nruns(idx))
    %collapse & reallocate
    this_data = file_data(curr_file,1); %so annoying...
    result_data{idx,1} = cat(1,this_data{:});
    fprintf('------n states = %i\n',size(result_data{idx,1},1))
    %just grab the first options file... that shouldn't matter here
    result_data{idx,2} = file_data{find(curr_file,1),2};
end


Nobs = cellfun(@(x) numel(x(:,1)),result_data(:,1));
fprintf('\n\n:::: excluding sets wtih < %i observations\n',opt.min_obs)
min_obs = Nobs >= opt.min_obs;
fprintf('\n      %i sets excluded (out of %i total)\n\n',sum(~min_obs),numel(min_obs))
result_data = result_data(min_obs,:);
uniq_params = uniq_params(min_obs,:);


%find how job_params matrix maps to param_varnames... now this is mega dumb
%and super confusing. You should've thought this out way better in the first place
Pmap = result_data{1,2};
Pmap.ItoE = {'ItoE'};
Pmap.EtoI = {'EtoI'};
%trial stimuli is a 1 x Ntargs cell. This cell contains 1 x Nstim vector
Pmap.trial_stimuli = repmat({'stim_A','stim_B'}, 1, numel(Pmap.stim_targs));
%stim targs is a 1 x Ntargs cell
Pmap.stim_targs = repmat({'targ_cells'}, 1, numel(Pmap.stim_targs));
Pmap = [Pmap.ItoE, Pmap.EtoI,Pmap.trial_stimuli,Pmap.stim_targs]; %matching "network_pair_info" format
net_type = cell(size(uniq_params,1),numel(param_varnams));
net_type = cell2table(net_type,'VariableNames',param_varnams);
for idx = 1:numel(param_varnams)
    p = param_varnams{idx};
    net_type.(p) = num2cell(uniq_params(:,ismember(Pmap,p)),2);
end

%net_type is supposed to match network_pair_info format
%this is stupid & obviously a hold-over from something I didn't implement well in the first place...
net_type.targ_cells = cellfun(@(x) stimtarg_labels(x),...
    net_type.targ_cells,'UniformOutput',false);

%add total magnitudes here
net_type.total_A = round(cellfun(@sum,net_type.stim_A),3);
net_type.total_B = round(cellfun(@sum,net_type.stim_A),3);


net_compare = net_type{:,IDvars}; %for comapring with network_pair_info
net_compare = cellfun(@(x) x(1),net_compare); %first one should be from get_network_params()


fig_fn = [sim_name '_%s'];

switch pulse_stim
    case 'yes'
        unit_measure = 'samples';
        fig_fn = sprintf(fig_fn,'total_samples');
    case 'rem'
        unit_measure = 's - onset';
        fig_fn = sprintf(fig_fn,'decision_timing');
    otherwise
        unit_measure = 's'; %like "seconds" not samples
        fig_fn = sprintf(fig_fn,'total_time');
end

switch outcome_stat
    case 'mu'
        Zlabel = sprintf('sampling (%s)',unit_measure);
    case 'med'
        Zlabel =  sprintf('median sampling (%s)',unit_measure);
        fig_fn = [fig_fn,'_med'];
    case 'logmu'
        Zlabel = sprintf('log_{10}(%s) sampling',unit_measure);
        fig_fn = [fig_fn,'_log'];
    case 'logmed'
        Zlabel = sprintf('med. log_{10}(%s) sampling',unit_measure);
        fig_fn = [fig_fn,'_med_log'];
end
switch opt.Xax
    case 'diff'
        fig_fn = [fig_fn '_diff'];
end

Ylab = 'p(x)';%Ylab = 'freq';

figdir = fullfile(figdir,sprintf('Nmin_%i',opt.min_obs)); %include the min observation cutoff
if ~isdir(figdir),mkdir(figdir);end

matblue = [0,0.4470,0.7410];
matorange = [0.8500,0.3250,0.0980];
BLcol = [103 115 122] ./ 255;

base_targ_cells = 'Eswitch'; %base everything off this
base_targ_labels = stimtarg_labels(strcmp(stimtarg_vals,base_targ_cells));

SPdata = []; %for scatter plot data
h = [];
plt_idx = 0;
figure;%set(gcf,'units','normalized','outerposition',[0 0 .4 1])


%this was for looking at a single network pair
%warning('hardcoded bits for single network pair')
%num_pairs = 1;num_net_types = 2;
%network_pair_info = network_pair_info(2);

for idx = 1:num_pairs
    
    curr_net_info = network_pair_info{idx};
    for j = 1:2
        
        plt_idx = plt_idx + 1;
        h(plt_idx) = subplot(ceil(num_net_types/2),2,plt_idx);
        hold on
        
        switch outcome_stat
            case 'mu'
                statfunc = @mean;
            case 'med'
                statfunc = @median;
            case 'logmu'
                %protect against inf errors too
                statfunc = @(x) mean(log10(x(x~=0)));
            case 'logmed'
                statfunc = @(x) median(log10(x(x~=0)));
        end
        
        %find the right results for network set-up
        net_ind = curr_net_info{j,IDvars};
        net_ind = ismember(net_compare,net_ind,'rows');
        if isempty(result_data(net_ind,1)),continue;end
        curr_data = result_data(net_ind,1);
        %there's no preference.. both stimuli are the same so relabel these
        for kidx = 1:numel(curr_data)
            curr_data{kidx}.state = strrep(curr_data{kidx}.state,'stim_B','stim_A');
        end
        curr_data = cellfun(@(x) varfun(statfunc,x,'InputVariables','data',...
            'GroupingVariables','state') ,curr_data,'UniformOutput',false);%summary statistic
        curr_data = cellfun(@(x) x(:,[1,size(x,2)]),curr_data,'UniformOutput',false); %remove count variable
        curr_data = cellfun(@(x) array2table(x{:,size(x,2)}','Variablenames',strrep(x.state,'stim','data')),...
            curr_data,'UniformOutput',false); %turn into 1 x 2 table w/ stim A/B as varnames
        curr_data = cat(1,curr_data{:});
        %now take the net info as well, so it's easy
        curr_data = [net_type(net_ind,:),curr_data];
        
        
        Si = cellfun(@(x) strcmp(x,base_targ_labels),curr_data.targ_cells,'UniformOutput',false);
        %get ratios
        stim_ratios = curr_data(:,{'stim_A'});
        stim_ratios.stim_A = cellfun(@(x,y) x(y) ./ sum(x),stim_ratios.stim_A,Si); %Eswitch/Estay
        stim_ratios.Properties.VariableNames = strrep(stim_ratios.Properties.VariableNames,'stim','ratio');
        curr_data = [curr_data,stim_ratios];
        curr_data = sortrows(curr_data,'ratio_A'); %sort by ratio A
        
        %get differences
        curr_data.diff_A = cellfun(@(x,y) x(y) - x(~y),curr_data.stim_A,Si); %Eswitch - Estay
        
        Smags = unique(curr_data.total_A); %intensities
        for kidx = 1:numel(Smags)
            sm = curr_data.total_A == Smags(kidx);
            switch opt.Xax
                case 'ratio'
                    plot(curr_data.ratio_A(sm),curr_data.data_A(sm),'LineWidth',3)
                case 'diff'
                    plot(curr_data.diff_A(sm),curr_data.data_A(sm),'LineWidth',3)
            end
        end
        switch opt.Xax
            case 'ratio'
                axis tight;xlim([0:1])
                legend_labs = cellfun(@(x) sprintf('%.0f Hz total',x),num2cell(Smags),'UniformOutput',false);
                pause(1);legend(legend_labs,'Location','best','Box','off');pause(1)
                xtick = num2cell(get(gca,'XTick'));
                xtick = cellfun(@(x) sprintf('%1.1f/%.1f',x,1-x),xtick,'UniformOutput',false);
                xtick = strrep(xtick,'0.','.');
                xtick = strrep(xtick,'1.0','1');
                xtick = strrep(xtick,'.0','0');
                set(gca,'XTickLabel',xtick)
            case 'diff'
                axis tight;
                legend_labs = cellfun(@(x) sprintf('%.0f Hz total',x),num2cell(Smags),'UniformOutput',false);
                pause(1);legend(legend_labs,'Location','best','Box','off');pause(1)
        end
        
        hold off
        
        if plt_idx == num_net_types-1 || plt_idx == num_net_types
            mix_info = {'Estay','Eswitch'};
            %mix_info = sprintf('%s / total',mix_info{strcmp(mix_info,base_targ)});
            mix_info = sprintf('%s / %s',mix_info{strcmp(mix_info,base_targ_cells)},...
                mix_info{~strcmp(mix_info,base_targ_cells)});
            mix_info = strrep(mix_info,'E','E-');
            switch opt.Xax
                case 'diff'
                    mix_info = strrep(mix_info,' / ',' - ');
                    mix_info = [mix_info ' (Hz)'];
            end
            xlabel(mix_info,'FontWeight','bold')
            
        end
        if plt_idx == 1 || plt_idx == 2
            title(sprintf('%s networks',curr_net_info.Row{j}),'FontWeight','bold','Fontsize',14)
        end
        if mod(plt_idx,2) == 1
            ylabel(sprintf('network #%i\n%s',idx,Zlabel),'FontWeight','bold')
        end
        
        %organize data for scatter plot
        curr_data.net_index = repmat(plt_idx,size(curr_data,1),1); %index ID for scatter plot
        curr_data.pair_index = repmat(idx,size(curr_data,1),1); %index ID for scatter plot
        SPdata = [SPdata;curr_data];
    end
end

Mvars = {'net_index','pair_index','data_A','targ_cells','total_A','ratio_A','diff_A'};
Mdata = SPdata(:,Mvars);
Mdata.Properties.VariableNames{'data_A'} = 'duration';
Mdata.Properties.VariableNames{'targ_cells'} = 'type';
Mdata.Properties.VariableNames{'total_A'} = 'total';
Mdata.Properties.VariableNames{'ratio_A'} = 'ratio';
Mdata.Properties.VariableNames{'diff_A'} = 'diff';
Mdata.type = cat(1,Mdata.type{:});
Mdata.type = Mdata.type(:,1);
Mdir = fullfile(figdir,sprintf('analysis-%s',outcome_stat));
if ~isdir(Mdir),mkdir(Mdir);end
save(fullfile(Mdir,'model_data'),'Mdata')

%Mspec = 'duration ~ total + ratio + total:ratio';
%Mspec = 'duration ~ total^2*ratio^2';
%for idx = 1:numel(Mtypes)
%do seperately
%this_type = Mtypes{idx};
%net_data = Mdata(ismember(Mdata.type,this_type),:);
%save(fullfile(Mdir,sprintf('model_data-%s',this_type)),'net_data')
%stepwiselm(Mdata(ismember(Mdata.type,this_type),:),'ResponseVar','duration','upper','quadratic')
%m1 = fitlm(Mdata(ismember(Mdata.type,this_type),:),'duration ~ total*ratio');
%mdl = fitlm(Mdata(ismember(Mdata.type,this_type),:),Mspec);
%end

if num_pairs == 1
    orient landscape %this was for looking at a single network pair
else
    orient tall
end
switch outcome_stat
    case {'logmu','logmed'}
        linkaxes(h,'y')
        linkaxes(h(1:2:end),'x');linkaxes(h(2:2:end),'x')
    case {'mu','med'}
        % linkaxes(h(1:2:end),'x');linkaxes(h(2:2:end),'x')
        %axis tight
end

switch print_anything
    case 'yes'
        set(gcf, 'Renderer', 'painters')
        print(fullfile(figdir,fig_fn),'-djpeg')
        savefig(fullfile(figdir,fig_fn))
end

%scatter plot not needed

%
% close all;figure;orient portrait
% %scatter plot
% alph = .75;Msz = 75;
% Bcol = colormap('winter');Rcol = colormap('autumn');
% %SPdata.X = SPdata.stim_B ./ SPdata.stim_A;
% SPcells = {'slow','fast'};
% %markers = {'o','square','diamond','pentagram','hexagram'};
% markers = {'x','+','^','v','d'};
% for idx = 1:numel(SPcells)
%     %subplot(numel(SPcells),1,idx);hold on
%     hold on
%     curr_data = strcmp(SPdata.targ_cells,SPcells{idx});
%     %types = cat(1,SPdata.targ_cells{:});
%     %types = types(:,1);
%     %curr_data = strcmp(types,SPcells{idx});
%     curr_data = SPdata(curr_data,:);
%     curr_nets = unique(curr_data.net_index);
%     for plt_idx = 1:numel(curr_nets)
%         this_net = curr_data.net_index == curr_nets(plt_idx);
%         this_net = curr_data(this_net,:);
%         col_idx = floor(size(Bcol,1)./numel(curr_nets)).*(plt_idx-1) + 1; %color index
%         switch SPcells{idx}
%             case 'slow'
%                 col = Bcol(col_idx,:);
%             case 'fast'
%                 col = Rcol(col_idx,:);
%         end
%
%         %scatter(this_net.X,this_net.data_A,Msz,col,'filled','MarkerFaceAlpha',alph)
%         %scatter(this_net.data_B,this_net.data_A,Msz,col,'filled','MarkerFaceAlpha',alph)
%         %scatter(this_net.data_B,this_net.data_A,Msz,col,'filled','MarkerFaceAlpha',alph,'Marker',markers{plt_idx})
%         scatter(this_net.data_B,this_net.data_A,Msz,col,'Marker',markers{plt_idx},'Linewidth',1.25)
%         axis tight
%         title(sprintf('Implicit Competition'),...
%             'FontWeight','bold','Fontsize',14)
%         %ylabel(Zlabel,'FontWeight','bold')
%
%         %xlabel('proportion of alternative stimulus','FontWeight','bold')
%
%         xlabel(sprintf(['B - varied [' strrep(Zlabel,' sampling','') ']']),'FontWeight','bold')
%         ylabel(sprintf(['A - constant [' strrep(Zlabel,' sampling','') ']']),'FontWeight','bold')
%     end
% end
%
% lg_pos = legend(' ');
% if contains(lg_pos.Location,'east')
%     make_lg = 'right';
% else
%     make_lg = 'left';
% end
% if contains(lg_pos.Location,'north')
%     Y0 = .95;
% else
%     Y0 = .2;
% end
% delete(lg_pos)
% switch make_lg
%     case 'left'
%         X0 = .025; move_pt = .02;
%     case 'right'
%         X0 = .975; move_pt = -.02;%was   Y0 = .5
% end
% lg_fz = 16; get_ax_val = @(p,x) p*range(x)+min(x);
% xlim(xlim + [-(range(xlim)*.015),(range(xlim)*.015)]); %extra room
% ylim(ylim + [-(range(ylim)*.015),(range(ylim)*.015)]);
% X = get_ax_val(X0,xlim);
% text(X,get_ax_val(Y0,ylim),SPcells{1},'Fontsize',lg_fz,'FontWeight','bold','HorizontalAlignment',make_lg)
% text(X,get_ax_val(Y0-.1,ylim),SPcells{2},'Fontsize',lg_fz,'FontWeight','bold','HorizontalAlignment',make_lg)
% %X = get_ax_val(.975,xlim);
% %text(X,get_ax_val(.5,ylim),SPcells{1},'Fontsize',lg_fz,'FontWeight','bold','HorizontalAlignment','right')
% %text(X,get_ax_val(.4,ylim),SPcells{2},'Fontsize',lg_fz,'FontWeight','bold','HorizontalAlignment','right')
% for plt_idx = 1:numel(curr_nets)
%     col_idx = floor(size(Bcol,1)./numel(curr_nets)).*(plt_idx-1) + 1; %color index
%     %X = get_ax_val(.975-(plt_idx*.02),xlim);
%     %scatter(X,get_ax_val(.45,ylim),Msz,Bcol(col_idx,:),'filled','MarkerFaceAlpha',alph)
%     %scatter(X,get_ax_val(.35,ylim),Msz,Rcol(col_idx,:),'filled','MarkerFaceAlpha',alph)
%     X = get_ax_val(X0+(plt_idx*move_pt),xlim);
%
%     % %regular w/ colors
%     % scatter(X,get_ax_val(Y0-.05,ylim),Msz,Bcol(col_idx,:),'filled','MarkerFaceAlpha',alph)
%     % scatter(X,get_ax_val(Y0-.15,ylim),Msz,Rcol(col_idx,:),'filled','MarkerFaceAlpha',alph)
%
%     %for symbols
%     scatter(X,get_ax_val(Y0-.05,ylim),Msz,Bcol(col_idx,:),'Marker',markers{plt_idx})
%     scatter(X,get_ax_val(Y0-.15,ylim),Msz,Rcol(col_idx,:),'Marker',markers{plt_idx})
% end
%
% set(gca,'FontSize',18)
% switch print_anything
%     case 'yes'
%         print(fullfile(figdir,[fig_fn '-scatter']),'-djpeg')
%         savefig(fullfile(figdir,[fig_fn '-scatter']))
% end


%info about simulation
num_states = cellfun(@(x) size(x{1},1),num2cell(result_data,2));
need_more = num_states < 10000;
need_more = net_type(need_more,:);
current_count = num_states(num_states < 10000);
for idx = 1:num_pairs
    curr_net_info = network_pair_info{idx};
    for j = 1:2
        
        curr_data = table2cell(curr_net_info(j,IDvars));
        curr_data = cellfun(@(x) isequal(x,curr_data),... %ugly indexing & transform here..
            num2cell(table2cell(need_more(:,IDvars)),2));
        if sum(curr_data) > 0
            curr_data = find(curr_data);
            fprintf('\nnetwork #%i %s has < 10k states',idx,curr_net_info.targ_cells{j})
            fprintf('\n---parameter sets:\n')
            for h = 1:numel(curr_data)
                disp(need_more(curr_data(h),:))
                fprintf('--- n = %i\n',current_count(curr_data(h)))
            end
            fprintf('\n------------------------\n')
        end
        
        BLinfo = curr_net_info(j,IDvars);
        BLinfo{:,startsWith(param_varnams,'stim')} = 0; BLinfo.targ_cells = 'baseline';
        curr_data = cellfun(@(x) isequal(x,table2cell(BLinfo)),... %ugly indexing & transform here..
            num2cell(table2cell(need_more),2));
        if sum(curr_data) > 0
            curr_data = find(curr_data);
            fprintf('\nnetwork #%i %s has < 10k states',idx,curr_net_info.targ_cells{j})
            fprintf('\n---parameter sets:\n')
            for h = 1:numel(curr_data)
                disp(need_more(curr_data(h),:))
                fprintf('--- n = %i\n',current_count(curr_data(h)))
            end
            fprintf('\n------------------------\n')
        end
        
        
        
        
    end
    
end

switch summary_stats
    case 'yes'
        %summary stats
        fprintf('\n------------------------\n')
        fprintf('Summary statistics\n')
        fprintf('%s:\n',Zlabel)
        fprintf('------------------------\n\n')
        for idx = 1:num_types
            fprintf('\n------------------------\nNetwork #%i\n',idx)
            curr_net_info = network_pair_info{idx};
            Xstim = cell(2,1); %for testing difference between stim distributions
            for j = 1:2
                fprintf('---type: %s\n',curr_net_info{j,end})
                %find the right results for network set-up
                curr_data = cellfun(@(x) isequal(x,curr_net_info(j,:)),net_type,'UniformOutput',false);
                curr_data = cat(1,curr_data{:});
                curr_data = result_data{curr_data,1};
                switch outcome_stat
                    case 'logmu'
                        curr_data = log10(curr_data(curr_data~=0));
                end
                Xstim{j} = curr_data;
                
                fprintf('            stimulus = %.2f\n',curr_net_info{j,3})
                fprintf('            ---mean = %.2f\n',mean(curr_data))
                
                
                %                 %take control data
                %                 BLinfo = [curr_net_info(j,1:2), {0,'baseline'}];
                %                 curr_data = cellfun(@(x) isequal(x,BLinfo),net_type,'UniformOutput',false);
                %                 curr_data = cat(1,curr_data{:});
                %                 fprintf('            baseline = %.2f\n',outcome(curr_data))
            end
            
            fprintf('\n---hyp. test: mu stim durrations\n')
            switch outcome_stat
                case 'logmu'
                    Xstim = cellfun(@(x) log10(x(x~=0)),Xstim,'UniformOutput',false);
            end
            [~,pval] = ttest2(Xstim{1},Xstim{2}); %regular old t-test
            fprintf('t-test p = %.3f\n',pval)
            [CI,H] = boot_mean_diffs(Xstim{1},Xstim{2},10000);
            fprintf('bootstrap test: %s\n',H)
            fprintf('bootstrap CI: %.2f, %.2f\n',CI)
        end
end
end


