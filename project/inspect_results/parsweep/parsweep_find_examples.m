clear
clc
format compact
close all

%this takes the results from parsweep_results() and picks out example
%networks across the parameter range. This code will mark the example
%networks and save their parameters in project/helper_functions/network_pairs/

sim_name = 'parsweep_D2t_very_slow_baseline';
%assume you're running this from project/inspect_results/parsweep
basedir = strsplit(fileparts(pwd),'project'); 
basedir = fullfile(basedir{1},'project');
%basedir = '~/Desktop/work/rotation/project/';%project directory (should be ../../)


save_netfile = 'no'; %yes/no (saves the example parameters into a mat file, used by other functions)
load_netfile = 'yes'; %'yes' loads existing examples (for plotting), 'no' finds new examples 
save_figs = 'yes';
HMtype = 'grid'; %'grid' | 'interp'
do_3dfig = 'no'; %yes/no

%---sim setup-----------------
Flabel = 'D2t-slower'; %network pairs will be saved with this filename
figdir = fullfile(basedir,'Results',['figures_' sim_name]);
resdir = fullfile(basedir,'Results',sim_name);
helper_dir = fullfile(basedir,'helper_functions');
addpath(helper_dir)
svdir = fullfile(helper_dir,'network_pairs');
fig_out_dir = fullfile(figdir,'example_networks'); %where these figs get saved to
if ~isdir(svdir),mkdir(svdir);end;if ~isdir(fig_out_dir),mkdir(fig_out_dir);end
FN = fullfile(svdir,Flabel);

%get results file
result_data = load(fullfile(resdir,'summary_file'));
result_data = result_data.result_data;

%get data-of-interest
ItoE = cellfun(@(x)  x.ItoE,result_data(:,2));
EtoI = cellfun(@(x)  x.EtoI,result_data(:,2));
%state_dur = cellfun(@(x) mean(x),result_data(:,1)); %"durations" reserved for output file
state_dur = cellfun(@(x) mean(log10(x+eps)),result_data(:,1));
Sdurs = 10.^state_dur; %in seconds

%slow_range = log10([50,70]); %seconds
slow_range = log10([200,300]); %seconds
fast_range = log10([1, 1.5]);
%many more slow, than fast. So start with the slow networks
in_range = @(x,y) x >= y(1) & x <= y(2);     %find durations X within target range Y (two element vec)


slow_nets = in_range(state_dur,slow_range);
fast_nets = in_range(state_dur,fast_range);

fprintf('\n::::::::slow networks::::::::\n')
fprintf('---range = %.2f - %.2f\n',slow_range)
fprintf('---total networks = %i\n',sum(slow_nets))

fprintf('\n::::::::fast networks::::::::\n')
fprintf('---range = %.2f - %.2f\n',fast_range)
fprintf('---total networks = %i\n',sum(fast_nets))


switch HMtype
    case 'grid'
        HM = openfig(fullfile(figdir,'logmean_duration','heatmap_nointerp.fig'));
    case 'interp'
        HM = openfig(fullfile(figdir,'logmean_duration','heatmap.fig'));
end
hold on
HMdata = gca;

HMdims = get(HMdata,'Children');
HMdims = size(HMdims.CData);
Nx = HMdims(1); Ny = HMdims(2);
switch HMtype
    case 'grid'
        Yax = linspace(.75,0,Ny);
        Xax = linspace(0.1,12.5,Nx);
    case 'interp'
        Yax = linspace(max(EtoI),min(EtoI),Ny);
        Xax = linspace(min(ItoE),max(ItoE),Nx);
end

nearest_ind = @(x,y) find(abs(x-y) == min(abs(x-y)),1); %return index of closest value
nearest_val = @(x,y) y(nearest_ind(x,y)); %return closest value

netX = num2cell(ItoE);
netX = cellfun(@(x) nearest_ind(x,Xax),netX);

netY = num2cell(EtoI);
netY = cellfun(@(x) nearest_ind(x,Yax),netY);

cand_nets = slow_nets | fast_nets;

switch HMtype
    case 'interp'
        scatter(netX(cand_nets),netY(cand_nets),'black')
end

hold off

switch do_3dfig
    case 'yes'
        pause(1)
        SP = openfig(fullfile(figdir,'logmean_duration','surface_plot.fig'));pause(1);gcf
        hold on
        
        scatter3(ItoE(cand_nets),EtoI(cand_nets),state_dur(cand_nets),40,'black','filled',...
            'MarkerFaceAlpha',1,'MarkerEdgeAlpha',1); %mark 'em
end
% figure()
% subplot(2,2,[1:2])
% histogram(Sdurs(slow_nets))
% title('slow network candidates');xlabel('durations (s)')
% subplot(2,2,3)
% scatter(EtoI(slow_nets),Sdurs(slow_nets));ylabel('durations (s)');xlabel('EtoI')
% subplot(2,2,4)
% scatter(ItoE(slow_nets),Sdurs(slow_nets));ylabel('durations (s)');xlabel('ItoE')



%test inds
param_perc = @(x,y) (range(y)*x )+ min(y); %return the Xth percentile value from parameter range Y


Npairs = 5;
network_pairs = cell(Npairs,1);

%find the one at the "top of the curve"
minmax_norm = @(x) (x - min(x)) ./ (max(x) - min(x));

center_pair = array2table(NaN(2,3),'VariableNames',{'ItoE','EtoI','duration'},'RowNames',{'slow','fast'});

XYcoords = [ItoE,EtoI];
XYcoords = num2cell(XYcoords,1);
XYcoords = cellfun(minmax_norm ,XYcoords,'UniformOutput',false);

slowP = [ItoE(slow_nets),EtoI(slow_nets)];
slowXY = cellfun(@(x) x(slow_nets),XYcoords,'UniformOutput',false);
slowXY = cat(2,slowXY{:});

fastP = [ItoE(fast_nets),EtoI(fast_nets)];
fastXY = cellfun(@(x) x(fast_nets),XYcoords,'UniformOutput',false);
fastXY = cat(2,fastXY{:});


minP = pdist2([0,0],fastXY)'; %was pdist2([0,0],slowXY)'
minP = find(minP == min(minP)); %closest to origin
net_coords = fastXY(minP,:); %save this for next step
fastP = fastP(minP,:);
curr_net = ItoE == fastP(1) & EtoI == fastP(2);
curr_net = find(curr_net);
center_pair{'fast','ItoE'} = ItoE(curr_net);
center_pair{'fast','EtoI'} = EtoI(curr_net);
center_pair{'fast','duration'} = Sdurs(curr_net);

%minP = pdist2([0,0],fastXY)'; %can also do origin like above
minP = pdist2(net_coords,slowXY)'; %can also do origin like above
minP = find(minP == min(minP)); %closest to slow net
slowP = slowP(minP,:);
curr_net = ItoE == slowP(1) & EtoI == slowP(2);
curr_net = find(curr_net);
center_pair{'slow','ItoE'} = ItoE(curr_net);
center_pair{'slow','EtoI'} = EtoI(curr_net);
center_pair{'slow','duration'} = Sdurs(curr_net);

network_pairs{5} = center_pair;


%find the rest
p.ItoE = ItoE;
p.EtoI = EtoI;
range_vals = [1, .5]; %get one pair at the extreme, one at half-way
p_types = {'ItoE','EtoI'};

pair_ind = 0;
for idx = 1:numel(p_types)
    
    curr_Ps = p.(p_types{idx}); %connection strength values for ItoE or EtoI
    switch p_types{idx}
        case 'ItoE'
            this_arm.fast = p.ItoE > center_pair{'fast','ItoE'};
            this_arm.slow = p.ItoE > center_pair{'slow','ItoE'} & p.EtoI < center_pair{'slow','EtoI'};
            %this_arm = p.ItoE > center_pair{'fast','ItoE'} & p.EtoI < center_pair{'fast','EtoI'};
            
        case 'EtoI'
            this_arm.fast = p.EtoI > center_pair{'fast','EtoI'};
            this_arm.slow = p.EtoI > center_pair{'slow','EtoI'} & p.EtoI > center_pair{'slow','EtoI'};
            %this_arm = p.ItoE < center_pair{'fast','ItoE'} & p.EtoI > center_pair{'fast','EtoI'};
            
    end
    
    for RVidx = 1:numel(range_vals)
        
        pair_ind = pair_ind + 1;
        net_pair = array2table(NaN(2,3),'VariableNames',{'ItoE','EtoI','duration'},'RowNames',{'slow','fast'});
        
        %find the fast network
        curr_RV = range_vals(RVidx); %where in the parameter space
        if pair_ind == 2
            warning('hardcoded thing for D2t-slower right here...')
            curr_RV = .65;
        end
        
        param_range = curr_Ps(fast_nets & this_arm.fast); %find the range for this "arm"
        
        curr_net = param_perc(curr_RV,param_range);
        curr_net = nearest_val(curr_net,param_range);
        curr_net = find(curr_Ps == curr_net & fast_nets);
        
        net_pair{'fast','ItoE'} = ItoE(curr_net);
        net_pair{'fast','EtoI'} = EtoI(curr_net);
        net_pair{'fast','duration'} = Sdurs(curr_net);
        
        %find the matching slow one
        curr_net = nearest_val(net_pair{'fast',p_types{idx}},curr_Ps(slow_nets & this_arm.slow));
        curr_net = find(curr_Ps == curr_net & slow_nets);
        if numel(curr_net) > 1
            switch p_types{idx}
                case 'ItoE'
                    %find the lowest EtoI
                    [~,this_one] = min(EtoI(curr_net));
                case 'EtoI'
                    [~,this_one] = min(ItoE(curr_net));
            end
            curr_net = curr_net(this_one);
        end
        
        net_pair{'slow','ItoE'} = ItoE(curr_net);
        net_pair{'slow','EtoI'} = EtoI(curr_net);
        net_pair{'slow','duration'} = Sdurs(curr_net);
        
        network_pairs{pair_ind} = net_pair;
    end
end
%save the network pair data
switch load_netfile
    case 'yes'
        network_pairs = load(FN);
        network_pairs = network_pairs.network_pairs;
end

%mark pairs on the big figure

X = cellfun(@(x) x{:,'ItoE'},network_pairs,'UniformOutput',false);
Y = cellfun(@(x) x{:,'EtoI'},network_pairs,'UniformOutput',false);
Z = cellfun(@(x) log10(x{:,'duration'}),network_pairs,'UniformOutput',false);
X = cat(1,X{:});Y = cat(1,Y{:});Z = cat(1,Z{:});

switch do_3dfig
    case 'yes'
        figure(SP) %return focus to this
        hold on
        
        scatter3(X,Y,Z,1000,'red','p','filled','MarkerFaceAlpha',1,'MarkerEdgeAlpha',1); %mark 'em w/ stars
        hold off
        switch save_figs
            case 'yes'
                print(fullfile(fig_out_dir,'surface_plot_examples'),'-djpeg','-r400')%print high-res
        end
end
%now for the heatmap

%need a logical showing all the networks you picked...
HMcoords = [ItoE,EtoI];
HM_X = NaN(size(X));
HM_Y = NaN(size(X));
for idx = 1:numel(X)
   curr_coords = ismember(HMcoords,[X(idx),Y(idx)],'rows');
   HM_X(idx) = netX(curr_coords);
   HM_Y(idx) = netY(curr_coords);
end

figure(HM);set(gcf, 'renderer', 'painters')
hold on
%here's original red star marking
%scatter(netX(HMcoords),netY(HMcoords),500,'red','p','filled','MarkerFaceAlpha',1,'MarkerEdgeAlpha',1);
%netX = netX(HMcoords); netY = netY(HMcoords);
net_symbs = {'o','square','^','diamond','v'}; %closed for fast nets, open for slow nets
net_symbs = repmat(net_symbs,2,1);
net_symbs = net_symbs(:);
net_plots = cell2table(cell(Npairs*2,4),'VariableNames',{'marker','fast','X','Y'});
net_plots.marker = net_symbs;
net_plots.fast = Z < median(Z);
net_plots.X = HM_X;
net_plots.Y = HM_Y;
mk_sz = 300;
mk_ln = 3;
for idx = 1:numel(net_plots(:,1))
    if net_plots.fast(idx)
        scatter(net_plots.X(idx),net_plots.Y(idx),mk_sz,...
            'red',net_plots.marker{idx},'filled','MarkerFaceAlpha',1,'MarkerEdgeAlpha',1);
    else
        scatter(net_plots.X(idx),net_plots.Y(idx),mk_sz,...
            'red',net_plots.marker{idx},'MarkerFaceAlpha',1,'MarkerEdgeAlpha',1,...
            'LineWidth',mk_ln);
    end
end


%fix the colorbar axes
cb = colorbar();
ticklabs = 10.^cb.Ticks; %in seconds
ticklabs = cellfun(@(x) sprintf('%.0f',x),num2cell(ticklabs),'Uniformoutput',false);
cb.TickLabels = ticklabs;
cb.Label.String = 'seconds (log scale)';

hold off
switch save_figs
    case 'yes'
        switch HMtype
            case 'grid'
                print(fullfile(fig_out_dir,'heatmap_nointerp_examples'),'-djpeg','-r400')%print high-res
                savefig(fullfile(fig_out_dir,'heatmap_nointerp_examples'))
            case 'interp'
                print(fullfile(fig_out_dir,'heatmap_examples'),'-djpeg','-r400')%print high-res
        end
end


%save the network pair data
switch save_netfile
    case 'yes'
        save(FN,'network_pairs')
end


