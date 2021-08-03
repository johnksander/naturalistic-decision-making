function [EtoE,EtoI,ItoE,ItoI,ItoI_cross,EtoE_cross] = connection_logicals(celltype,num_cells)
%make logical matricies for different connections based on 
%celltype logical vectors
%inputs: number of total cells, logical vectors for pool type and
%excitatory/inhibitory cell type. 
%outputs: logical matricies for excitatory-excitatory,
%excitatory-inhibitory, and inhibitory-excitatory based on scheme specified
%in this function. 


EtoE = repmat(celltype.excit,1,num_cells) & repmat(celltype.excit',num_cells,1);
EtoI = repmat(celltype.excit,1,num_cells) & repmat(celltype.inhib',num_cells,1);
ItoE = repmat(celltype.inhib,1,num_cells) & repmat(celltype.excit',num_cells,1);
self_connection = repmat(celltype.pool_stay,1,num_cells) == repmat(celltype.pool_stay',num_cells,1);
EtoE = EtoE & self_connection; %only self-celltype.excitation within group
EtoI = EtoI & ~self_connection; %E to I connection is across group
ItoE = ItoE & self_connection; %I to E connection is within group

%here, "self_connection" really means same pool (switch/stay)... 

%for the reviews, adding ItoI (self), ItoI (cross), EtoE (cross) 
ItoI = repmat(celltype.inhib,1,num_cells) & repmat(celltype.inhib',num_cells,1);
EtoE_cross = repmat(celltype.excit,1,num_cells) & repmat(celltype.excit',num_cells,1);

ItoI_cross = ItoI & ~self_connection; %I to I cross is across group
ItoI = ItoI & self_connection; % I to I is within group, self connection
EtoE_cross = EtoE_cross & ~self_connection; % E to E cross is across group


%maybe figure out if these need to be used later
%celltype.pool_stay_mat = repmat(celltype.pool_stay,1,num_cells) | repmat(celltype.pool_stay',num_cells,1); 
%celltype.pool_switch_mat = repmat(celltype.pool_switch,1,num_cells) | repmat(celltype.pool_switch',num_cells,1);

% figure
% subplot(1,3,1);imagesc(EtoE);title('EtoE');hold on
% subplot(1,3,2);imagesc(ItoE);title('ItoE')
% subplot(1,3,3);imagesc(EtoI);title('EtoI')
% 
% figure
% subplot(1,3,1);imagesc(ItoI);title('ItoI');hold on
% subplot(1,3,2);imagesc(ItoI_cross);title('ItoI_cross')
% subplot(1,3,3);imagesc(EtoE_cross);title('EtoE_cross')

