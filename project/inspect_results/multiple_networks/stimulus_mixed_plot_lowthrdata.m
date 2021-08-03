clear; close all
clc;format compact

%---this adds the low threshold data (from driver_taste_mixture_LOWTHR.m)
%to figures 3 and 4 as dotted lines. You must run stimulus_mixed.m first to
%process the data and generate supplementary figures 3 and 4. 

basedir = '~/Desktop/rotation/project'; %project directory!
main_sim = 'nets_mixstim'; %job name for the primary similation 
lowthr_sim = 'nets_mixstim-NOBSTEST-THR01'; %Job name for the low threshold simulation 
%min # of observations (states), this is important for loading correct data
min_obs = 250; 
%the .fig files corresponding to supplementary figures 3 and 4 (from stimulus_mixed.m) 
fns = {'nets_mixstim_total_time_log.fig','nets_mixstim_total_time_log_diff.fig'};


lowthr_data = fullfile(basedir,'Results',sprintf('figures_%s',lowthr_sim),'durations',...
   sprintf('Nmin_%i',min_obs),'analysis-logmu');
resFN = fullfile(lowthr_data,'model_data.mat');

main_figdir = fullfile(basedir,'Results',sprintf('figures_%s',main_sim),'durations',...
   sprintf('Nmin_%i',min_obs));

ftype = {'ratio','diff'};
new_data = load(resFN);
new_data = new_data.Mdata;
plots2update = unique(new_data.net_index);

for fidx = 1:numel(fns)
    f = openfig(fullfile(main_figdir,fns{fidx}));
    set(f,'defaultLegendAutoUpdate','off');
    shg
    for idx = 1:numel(plots2update)
        curr_idx = plots2update(idx);
        curr_plt = subplot(5,2,curr_idx);
        intensities = {curr_plt.Children.DisplayName}; %line display names
        intensities = strrep(intensities,' Hz total','');
        intensities = str2double(intensities);
        data2add = new_data.net_index == curr_idx;
        data2add = new_data(data2add,:);
        %existing data with bistability checks during simulation
        curr_line = intensities == round(unique(data2add.total));
        if sum(curr_line) ~= 1,error('did not match total intensity');end
        prev_data = curr_plt.Children(curr_line);
        switch ftype{fidx}
            case 'ratio'
                Xnew = data2add.ratio;
            case 'diff'
                Xnew = data2add.diff;
        end
        pts2add = Xnew(~ismember(Xnew,prev_data.XData));
        %the missing stuff is always on the lower end, only add points if
        %they're beyond the range we got with regular simulation (i.e. sims
        %including bistability tests).
        pts2add = pts2add(pts2add < min(prev_data.XData));
        if ~isempty(pts2add)
            pts2add = ismember(Xnew,pts2add);
            %need to add this data in the correct color & linesz, but dashed line
            lnsz = prev_data.LineWidth;
            lncol = prev_data.Color;
            x = Xnew(pts2add);
            y = data2add.duration(pts2add);
            hold on
            curr_plt.Legend.AutoUpdate = 'off';
            plot(x,y,'--','Color',lncol,'LineWidth',lnsz)
        end
    end
    %fix all yaxes and add network symbol
    net_symbs = {'o','square','^','diamond','v'}; %closed for fast nets, open for slow nets
    net_symbs = repmat(net_symbs,2,1);
    net_symbs = net_symbs(:);
    mk_sz = 300; %for adding netword symbs
    mk_ln = 1;
    for idx = 1:10
        curr_plt = subplot(5,2,idx);
        Ytick = get(gca,'YTick');
        %Ytick = linspace(Ytick(1),Ytick(end),5);
        %set(gca,'YTick',Ytick)
        Ytick = 10.^Ytick;
        Ytick = cellfun(@(x) sprintf('%.1fs',x),num2cell(Ytick),'UniformOutput',false);
        Ytick = strrep(Ytick,'.0s','s');
        Ytick = strrep(Ytick,'0.','.');
        Ytick = strrep(Ytick,'s',''); %went from "sampling" label to just seconds...
        set(gca,'YTickLabel',Ytick);
        hold on
        set(gcf,'defaultLegendAutoUpdate','on');
        lg = get(gca,'legend');
        lg.AutoUpdate = 'on';
        if mod(idx,2) == 1 %slow networks
            ylabel('seconds (log scale)','FontWeight','bold')
            scatter(NaN,NaN,mk_sz,'black',net_symbs{idx},...
                'MarkerFaceAlpha',1,'MarkerEdgeAlpha',1,'LineWidth',mk_ln);
        else %fast networks
            ylabel('')
            scatter(NaN,NaN,mk_sz,'black',net_symbs{idx},'filled',...
                'MarkerFaceAlpha',1,'MarkerEdgeAlpha',1);
        end
        lg.String{end} = 'network';
    end
    newFN = sprintf('new_%s',fns{fidx});
    newFN = strrep(newFN,'.fig','');
    print(newFN,'-djpeg','-r400')
    
    close(f)
    
    %load the model datafile
    %~/Desktop/work/ACClab/rotation/project/Results/figures_nets_mixstim-NOBSTEST/durations/Nmin_250/analysis-logmu
    %can also grab the figure if that's too much for some reason...
end
