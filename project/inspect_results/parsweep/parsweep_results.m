clear
clc
format compact
hold off;close all

sim_name = 'parsweep_D2t_very_slow_baseline'; %parameter sweep job name 
%assume you're running this from project/inspect_results/parsweep
basedir = strsplit(fileparts(pwd),'project'); 
basedir = fullfile(basedir{1},'project');
%basedir = '~/Desktop/work/rotation/project/';%project directory (should be ../../)


num_workers = 24; %available workers on local machine for parfor loading results 
rescale_plane = 'on'; 
mask_trimming = 'on'; 
outcome_stat = 'logmu';  %'mu' | 'med' | 'logmu' ||| 'E-rate' | 'I-rate'
do_3dfig = 'no'; %yes/no
%set the outcome_stat as 'I-rate'|'E-rate' for spikerate plots, do 'logmu'
%for log mean state-duration 

%result summaries
fontsz = 20;
stim_labels = {'stim A','stim B'};
limit_prange = 'yes'; %'yes' | 'no' if yes, set maximums for connection parameters

EI_max = .75; IE_max = 12.5; %these set connection maximums
Tmax = 300; %set a maximum duration for these plots 
Tmin = 1; %minimum duration 
min_states = 1; %must have at least 1 state duration... 

switch outcome_stat
    case {'E-rate','I-rate'}
        Tmax = inf;Tmin = -inf;min_states = 0;
        warning('duration filers off for spike plots')
end

%specify simulation
%---sim setup-----------------
figdir = fullfile(basedir,'Results',['figures_' sim_name]);
resdir = fullfile(basedir,'Results',sim_name);
addpath(fullfile(basedir,'helper_functions'))
sumFN = fullfile(resdir,'summary_file.mat');
%output_fns = dir(fullfile(resdir,['*',sim_name,'*.mat']));
output_fns = dir(fullfile(resdir,['*.mat'])); warning('loading all mat files in results directory (will break on checkpoint files!)')
output_fns = cellfun(@(x,y) fullfile(x,y),{output_fns.folder},{output_fns.name},'UniformOutput',false);
output_fns = output_fns(~endsWith(output_fns,'summary_file.mat'));
%get results
num_files = numel(output_fns);
file_data = cell(num_files,3);
gen_options = load(output_fns{1});
gen_options = gen_options.options;
timestep = gen_options.timestep;

if exist(sumFN) == 0
    %parfor stuff
    output_log = fullfile(resdir,'output_log.txt');
    special_progress_tracker = fullfile(resdir,'SPT.txt');
    if exist(special_progress_tracker) > 0
        delete(special_progress_tracker) %fresh start
    end
    c = parcluster('local');
    c.NumWorkers = num_workers;
    parpool(c,c.NumWorkers,'IdleTimeout',Inf)
    for idx = 1:num_files
        %if mod(idx,1000) == 0,fprintf('working on file #%i/%i...\n',idx,num_files);end
        curr_file = load(output_fns{idx});
        %store parameters
        %file_data{idx,2} = curr_file.options;
        %get state durations
        state_durations = curr_file.sim_results;
        state_durations = state_durations{1};
        if ~isempty(state_durations) %this was for running a job with spikerate data only...
            %just get all of them, baseline test. Everything that's not undecided
            valid_states = ~strcmpi(state_durations(:,end),'undecided');
            %state.count recorded in second col
            state_durations = state_durations(valid_states,2);
            state_durations = cat(1,state_durations{:});
            %convert to time
            state_durations = state_durations * timestep;
        else
            state_durations = []; %empty cell breaks stuff downstream
        end
        %ratecheck estimates
        Rcheck = curr_file.sim_results{4};
        %store durations, parameters, rate estimates
        file_data(idx,:) = {state_durations,curr_file.options,Rcheck};
        
        progress = worker_progress_tracker(special_progress_tracker);
        if mod(progress,floor(num_files * .1)) == 0 %at 10 percent
            progress = (progress / num_files) * 100;
            message = sprintf('----%.1f percent complete',progress);
            update_logfile(message,output_log)
        end
    end
    delete(gcp('nocreate'))
    
    %search for jobs with identical parameters, collapse distributions
    %get the randomized network parameters
    job_params = cellfun(@(x)  [x.ItoE, x.EtoI],file_data(:,2),'UniformOutput',false);
    job_params = vertcat(job_params{:});
    uniq_params = unique(job_params,'rows');
    num_jobs = size(uniq_params,1);
    fprintf('----------------------\n')
    fprintf('num jobs = %i\nunique parameter sets = %i\nduplicates = %i\n',num_files,num_jobs,num_files - num_jobs)
    
    %collapse duplicate job parameters
    result_data = cell(num_jobs,3);
    for idx = 1:num_jobs
        %find all matching
        curr_file = ismember(job_params,uniq_params(idx,:),'rows');
        %collapse & reallocate
        result_data{idx,1} = cell2mat(file_data(curr_file,1));
        %just grab the first options file... that shouldn't matter here
        result_data{idx,2} = file_data{find(curr_file,1),2};
        %rate estimates
        Rcheck_data = file_data(curr_file,3);
        if sum(~cellfun(@isempty,Rcheck_data)) > 0
            curr_rate.Erate = mean(cellfun(@(x) x.Erate,Rcheck_data));
            curr_rate.Irate = mean(cellfun(@(x) x.Irate,Rcheck_data));
            result_data{idx,3} = curr_rate;
        end
    end
    
    %save a big results file
    data_sz = whos('result_data');
    data_sz = data_sz.bytes / 1e6; %in MB
    if data_sz > 300
        fprintf('\nWARNING: summary file size = %.0f MB\n... summary file will not be saved\n',data_sz)
    else
        fprintf('\nsaving summary file...')
        save(sumFN,'result_data','num_jobs')
        fprintf('complete\n')
    end
    
else
    fprintf('loading summary file data')
    result_data = load(sumFN);
    num_jobs = result_data.num_jobs;
    result_data = result_data.result_data;
end


num_states = cellfun(@(x) numel(x),result_data(:,1));
mu_time = cellfun(@(x) mean(x),result_data(:,1));
fprintf('\n---jobs without data = %i\n',sum(num_states == 0))

overmax = mu_time > Tmax;
undermin = mu_time < Tmin;
Tinvalid = num_states < min_states;
fprintf('\n---Tmax cutoff = %i\n',Tmax) %before log transform... 
fprintf('---%i / %i jobs above cutoff\n',sum(overmax),num_jobs)
fprintf('\n---Tmin cutoff = %i\n',Tmin)
fprintf('---%i / %i jobs under cutoff\n',sum(undermin),num_jobs)
fprintf('\n---%i / %i jobs without data (< %i states)\n',sum(Tinvalid),num_jobs,min_states)

Tinvalid = Tinvalid | overmax | undermin;

%---narrowing parameter range down
switch limit_prange
    case 'yes'
        %find parameters < value. x is otpions field ('EtoI') and y is cutoff value
        param_OOB = @(x,y) cellfun(@(z)  z.(x),result_data(:,2)) <= y;
        
        EI_valid = param_OOB('EtoI',EI_max);
        IE_valid = param_OOB('ItoE',IE_max);
        fprintf('\n---E-to-I cutoff = %.2f\n',EI_max)
        fprintf('---%i / %i jobs under cutoff\n',sum(EI_valid),num_jobs)
        fprintf('\n---I-to-E cutoff = %.2f\n',IE_max)
        fprintf('---%i / %i jobs under cutoff\n',sum(IE_valid),num_jobs)
        
        Tinvalid = Tinvalid | ~EI_valid | ~IE_valid;
end

fprintf('\nnum valid jobs = %i\n',sum(~Tinvalid))



%stats
switch outcome_stat
    case 'mu'
        outcome = cellfun(@(x) mean(x),result_data(:,1));
        Zlabel = 'mean duration (s)';
        figdir = fullfile(figdir,'mean_duration');
    case 'med'
        outcome = cellfun(@(x) median(x),result_data(:,1));
        Zlabel = 'median duration (s)';
        figdir = fullfile(figdir,'med_duration');
    case 'logmu'
        outcome = cellfun(@(x) mean(log10(x+eps)),result_data(:,1));
        Zlabel = {'mean stay duration';'seconds (log scale)'};
        figdir = fullfile(figdir,'logmean_duration');
    case 'E-rate'
        outcome = cellfun(@(x) x.Erate,result_data(:,3));
        Zlabel = {'E spikerates';'Hz'};
        figdir = fullfile(figdir,'rates_excit');
    case 'I-rate'
        outcome = cellfun(@(x) x.Irate,result_data(:,3));
        Zlabel = {'I spikerates';'Hz'};
        figdir = fullfile(figdir,'rates_inhib');
end

% switch limit_prange
%     case 'yes'
%         figdir = fullfile(figdir,'trimmed_range');
% end

if ~isdir(figdir),mkdir(figdir);end
fprintf('figures will print to:\n%s\n',figdir)
return
outcome = outcome(~Tinvalid);
%get the network parameters
EtoE = cellfun(@(x)  x.EtoE,result_data(~Tinvalid,2));
ItoE = cellfun(@(x)  x.ItoE,result_data(~Tinvalid,2));
EtoI = cellfun(@(x)  x.EtoI,result_data(~Tinvalid,2));
num_jobs = numel(outcome);

%surface plot
figure
pointsz = 10; %was 30
plt_alph = .75;
num_gridlines = 400; 
xlin = linspace(min(ItoE),max(ItoE),num_gridlines);
ylin = linspace(min(EtoI),max(EtoI),num_gridlines);
[X,Y] = meshgrid(xlin,ylin);
f = scatteredInterpolant(ItoE,EtoI,outcome);
f.Method = 'natural';
Z = f(X,Y);
%---if you need to smooth the plane---
filtSD = 1.5;
Z = imgaussfilt(Z,filtSD);
%---old mask implementation
%mask = tril(ones(size(Z)),50);%mask = logical(flipud(mask));%Z(~mask) = NaN;
switch rescale_plane
    case 'on'
        Z(Z < 0) = 0;
        Z(Z > max(outcome)) = max(outcome);
end
switch mask_trimming
    case 'on'
        mesh2keep = false(size(X));
        rad2keep = .075; 
        %good_dist = @(X,x) (X - x).^2 <= mask_lim.^2; %map - point 
        minmax = @(x) (x-min(x(:))) ./ (max(x(:)) - min(x(:)));
        Xsc = minmax(ItoE); Ysc = minmax(EtoI); Zsc = minmax(outcome);
        Xmap = minmax(X); Ymap = minmax(Y); Zmap = minmax(Z);
        for idx = 1:num_jobs
            %x = ItoE(idx);y = EtoI(idx);z = outcome(idx); %coordinate for each datapoint 
            %sphere_voxels = ((Y - y).^2 + (X - x).^2 + (Z - z).^2)<= rad2keep.^2;
            %mesh2keep(sphere_voxels) = 1;
            
            x = Xsc(idx);y = Ysc(idx);z = Zsc(idx); %coordinate for each datapoint 
            good_voxels = (Ymap - y).^2 <= rad2keep.^2  & ...
                (Xmap - x).^2  <= rad2keep.^2  & ...
                (Zmap - z).^2 <= rad2keep.^2;
            %good_voxels = ((Ymap - y).^2 + (Xmap - x).^2 + (Zmap - z).^2)<= rad2keep.^2;
            mesh2keep(good_voxels) = true;

        end
        X(~mesh2keep) = NaN;Y(~mesh2keep) = NaN;Z(~mesh2keep) = NaN;
end

switch do_3dfig
    case 'yes'
        mesh(X,Y,Z,'FaceAlpha',plt_alph,'EdgeAlpha',plt_alph)
        axis tight; hold on
        %these feel like they need to be slightly bigger
        %scatter3(ItoE,EtoI,outcome,25,'black','filled','MarkerEdgeAlpha',1,'MarkerEdgeAlpha',1) %give them outlines
        scatter3(ItoE,EtoI,outcome,pointsz,'red','filled','MarkerFaceAlpha',1,'MarkerEdgeAlpha',1)
        xlabel({'within-pool inhibition';'(I-to-E strength)'},'FontWeight','b')
        ylabel({'cross-pool inhibition';'(E-to-I strength)'},'FontWeight','b')
        zlabel(Zlabel,'FontWeight','b')
        set(gca,'FontSize',fontsz)
        view(-45,27)
        %view(-124,31)
        %view(0,90) %that looks good too
        hidden off
        rotate3d on
        %also see--
        %https://www.mathworks.com/help/matlab/math/interpolating-scattered-data.html#bsovi2t
        switch rescale_plane
            case 'on'
                Zlim = get(gca,'ZLim');
                Zlim(1) = 0;
                Zlim(2) = max(outcome);
                set(gca,'ZLim',Zlim);
                caxis(Zlim)
        end
        %savefig(fullfile(figdir,'surface_plot'))
        %make it big
        set(gcf,'units','normalized','outerposition',[0 0 .75 1])
        %fix the labels
        xh = get(gca,'XLabel'); % Handle of the x label
        set(xh, 'Units', 'Normalized')
        xh_pos = get(xh, 'Position');
        %set(xh, 'Position',xh_pos+[-.05,.1,0],'Rotation',-24.5)
        set(xh, 'Position',xh_pos+[.05,.1,0],'Rotation',20.5)
        yh = get(gca,'YLabel'); % Handle of the y label
        set(yh, 'Units', 'Normalized')
        yh_pos = get(yh, 'Position');
        %set(yh, 'Position',yh_pos+ [.1,.15,0],'Rotation',13)
        set(yh, 'Position',yh_pos+ [-.075,.15,0],'Rotation',-19)
        set(gcf,'Renderer','painters')
        print(fullfile(figdir,'surface_plot'),'-djpeg','-r400')%print high-res
        
        %https://www.mathworks.com/matlabcentral/answers/41800-remove-sidewalls-from-surface-plots
        savefig(gcf,fullfile(figdir,'surface_plot'),'compact')
        %view(-24,24)
end
figure
hold off

Z = flipud(Z); %so the bottom left corner is low x, low y
switch rescale_plane
    case 'on'
        Z(Z < 0) = 0;
        Z(Z > max(outcome)) = max(outcome);
end
%mask = tril(ones(size(Z)),100);
%mask = logical(mask);
%Z(~mask) = NaN;
% colormap(parula)
imagesc(Z,'AlphaData',~isnan(Z))
xlabel('I-to-E strength')
ylabel('E-to-I strength')
title('state durations')
set(gca,'Fontsize',fontsz-4)
colb = colorbar;
colb.Label.String = Zlabel(end);
colb.FontSize = 16;
origXticks = get(gca,'Xtick');
Xticks = linspace(min(ItoE),max(ItoE),max(origXticks));
Xticks = Xticks(origXticks);
Xlabs = cellfun(@(x) sprintf('%.1f',x),num2cell(Xticks),'UniformOutput', false);
set(gca, 'XTickLabel', Xlabs)
origYticks = get(gca,'Ytick');
Yticks = linspace(max(EtoI),min(EtoI),max(origYticks));
%reset these real quick
origYticks = [1,origYticks(1:end-1)];
set(gca,'Ytick',origYticks);
Yticks = Yticks(origYticks);
Ylabs = cellfun(@(x) sprintf('%.2f',x),num2cell(Yticks),'UniformOutput', false);
set(gca, 'YTickLabel', Ylabs')
set(gca,'FontSize',fontsz-4)
print(fullfile(figdir,'heatmap'),'-djpeg','-r400')
savefig(gcf,fullfile(figdir,'heatmap'),'compact')



% %this is okay.....
% sz = linspace(25,400,num_jobs);
% c = colormap(summer(num_jobs));
% [~,inds] = sort(outcome,'descend');
% c = c(inds,:);
% sz = sz(inds);
% figure
% scatter(ItoE,EtoI,sz,c,'filled')
% colb = colorbar;
% Tlabs = colb.TickLabels;
% Tlabs = linspace(min(outcome),max(outcome),numel(Tlabs));
% Tlabs = num2cell(Tlabs);
% Tlabs = cellfun(@(x) sprintf('%.2f',x),Tlabs,'UniformOutput', false);
% colb.TickLabels = Tlabs;
% xlabel('I-to-E strength')
% ylabel('E-to-I strength')


hold off; close all


Ngrid = 100;
P.ItoE = linspace(0.1,12.5,Ngrid);
P.EtoI = linspace(0,.75,Ngrid);
[G.ItoE,G.EtoI] = meshgrid(P.ItoE,P.EtoI);
HM = NaN(Ngrid,Ngrid);
for idx = 1:num_jobs
    coords = G.ItoE == ItoE(idx) & G.EtoI == EtoI(idx);
    [x,y] = find(coords);
    HM(x,y) = outcome(idx);
end
HM = flipud(HM); %so y axis goes low EtoI to high 

colormap(parula)
imagesc(HM,'AlphaData',~isnan(HM))
set(gcf, 'renderer', 'painters')
xlabel('I-to-E strength')
ylabel('E-to-I strength')
title('state durations')
set(gca,'Fontsize',fontsz)
colb = colorbar;
switch outcome_stat
    case 'logmu'
        ticklabs = 10.^colb.Ticks; %in seconds
        ticklabs = cellfun(@(x) sprintf('%.0f',x),num2cell(ticklabs),'Uniformoutput',false);
        colb.TickLabels = ticklabs;
    case 'E-rate'
        title('excitatory cells')
        %need to round the ticks, otherwise label is forced off figure 
        colb.Ticks = min(floor(colb.Ticks)):1:max(ceil(colb.Ticks));
    case 'I-rate'
        title('inhibitory cells')
end
colb.Label.String = Zlabel(end);
origXticks = get(gca,'Xtick');
Xticks = P.ItoE(origXticks);
Xlabs = cellfun(@(x) sprintf('%.1f',x),num2cell(Xticks),'UniformOutput', false);
set(gca, 'XTickLabel', Xlabs)
origYticks = get(gca,'Ytick');
%reset these real quick
origYticks = [1,origYticks(1:end-1)];
set(gca,'Ytick',origYticks);
Yticks = flip(P.EtoI);
Yticks = Yticks(origYticks);
Ylabs = cellfun(@(x) sprintf('%.2f',x),num2cell(Yticks),'UniformOutput', false);
set(gca, 'YTickLabel', Ylabs')
set(gca,'FontSize',fontsz)
print(fullfile(figdir,'heatmap_nointerp'),'-djpeg','-r400')
savefig(gcf,fullfile(figdir,'heatmap_nointerp'),'compact')
save(fullfile(figdir,'heatmap_nointerp.mat'),'HM')
hold off; close all