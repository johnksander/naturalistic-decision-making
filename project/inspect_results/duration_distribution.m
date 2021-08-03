clear
clc
format compact


sim_name = 'nets_distribution_review'; %job name
%assume you're running this from project/inspect_results/
basedir = strsplit(fileparts(pwd),'project');
basedir = fullfile(basedir{1},'project');



%specify simulation
%---sim setup-----------------
figdir = fullfile(basedir,'Results',['figures_' sim_name]);
resdir = fullfile(basedir,'Results',sim_name);
output_fns = dir(fullfile(resdir,['*.mat'])); warning('loading all mat files in results directory (will break on checkpoint files!)')
output_fns = cellfun(@(x,y) fullfile(x,y),{output_fns.folder},{output_fns.name},'UniformOutput',false);

%get results
num_files = numel(output_fns);
file_data = cell(num_files,1);
gen_options = load(output_fns{1});
gen_options = gen_options.options;
timestep = gen_options.timestep;




for idx = 1:num_files
    
    curr_file = load(output_fns{idx});
    state_durations = curr_file.sim_results;
    state_durations = state_durations{1};
    %state.count recorded in second col
    state_durations = state_durations(:,2);
    state_durations = cat(1,state_durations{:});
    %convert to time
    state_durations = state_durations * timestep;
    file_data{idx} = state_durations;

end

file_data = cat(1,file_data{:});
%just take the first 10k, round numbers are nice 
state_durations = file_data(1:10e3); 


%plot
fz = 20;

% histogram(state_durations)
% set(gca,'FontSize',fz)
% ylabel('frequency','FontWeight','bold')
% xlabel('duration (s)','FontWeight','bold')
% set(gca,'box','off')
% FN = fullfile(figdir,'state_duration_distribution');
% %print(FN,'-djpeg','-r600');
% 
% 
% histfit(state_durations,49,'gamma')
% FN = fullfile(figdir,'gamma');
% %print(FN,'-djpeg','-r600');
% 
% 
% histfit(state_durations,49,'exponential')
% FN = fullfile(figdir,'exponential');
% %print(FN,'-djpeg','-r600');



close all
histogram(state_durations)
set(gca,'FontSize',fz)
ylabel('frequency','FontWeight','bold')
xlabel('duration (s)','FontWeight','bold')
set(gca,'box','off');
FN = fullfile(figdir,'dist_full');
%print(FN,'-djpeg','-r600');



close all
histogram(state_durations)
set(gca,'FontSize',fz)
ylabel('frequency','FontWeight','bold')
xlabel('duration (s)','FontWeight','bold')
set(gca,'box','off');
FN = fullfile(figdir,'dist_full_lognfit');
%print(FN,'-djpeg','-r600');
pd = fitdist(state_durations,'Lognormal');
hold on 

x = 0:.1:max(state_durations);
y = lognpdf(x,pd.mu,pd.sigma);
YLIM = max(get(gca,'YLim'));
plot(x,y *YLIM,'LineWidth',2);

FN = fullfile(figdir,'dist_full_lognfit');
%print(FN,'-djpeg','-r600');



Tmin = 1.5;
close all
trimmed_data = state_durations(state_durations >= Tmin);
histogram(trimmed_data)
set(gca,'FontSize',fz)
ylabel('frequency','FontWeight','bold')
xlabel('duration (s)','FontWeight','bold')
set(gca,'box','off');
pd = fitdist(trimmed_data,'Exponential');
hold on 

x = Tmin:.1:max(trimmed_data);
y = exppdf(x,pd.mu);
YLIM = max(get(gca,'YLim'));
plot(x,y *YLIM,'LineWidth',2);
set(gca,'XTick',[1,get(gca,'XTick')])
FN = fullfile(figdir,'dis_trimmed');
%print(FN,'-djpeg','-r600');


% histogram(state_durations)
% set(gca,'FontSize',fz)
% ylabel('frequency','FontWeight','bold')
% xlabel('duration (s)','FontWeight','bold')
% set(gca,'box','off')
% FN = fullfile(figdir,'state_duration_distribution');
% %print(FN,'-djpeg','-r600');
% 
% 
% histfit(state_durations,49,'gamma')
% FN = fullfile(figdir,'gamma');
% %print(FN,'-djpeg','-r600');
% 
% 
% histfit(state_durations,49,'exponential')
% FN = fullfile(figdir,'exponential');
% %print(FN,'-djpeg','-r600');


% hold on
% plot(gammaX,gammaY)
% plot(exX,exY)
% keyboard
% 
% hold on
% histfit(state_durations,num_bins,'exponential')
% 
% set(gca,'FontSize',fz)
% ylabel('frequency','FontWeight','bold')
% xlabel('duration (s)','FontWeight','bold')
% set(gca,'box','off');keyboard
% 






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
% %print('state_duration_distribution','-djpeg','-r600')
