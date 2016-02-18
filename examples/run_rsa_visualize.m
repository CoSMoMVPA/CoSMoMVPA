%% RSA Visualize
%

%% Load data in EV and VT mask
% load datasets cosmo_fmri_dataset

config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');
% >@@>
data_fn=[data_path '/glm_T_stats_perrun.nii'];
targets=repmat(1:6,1,10)';
ev_ds = cosmo_fmri_dataset(data_fn, ...
                            'mask',[data_path '/ev_mask.nii'],...
                            'targets',targets);

vt_ds = cosmo_fmri_dataset(data_fn, ...
                            'mask',[data_path '/vt_mask.nii'],...
                            'targets',targets);
% <@@<

% compute average for each unique target, so that the datasets have 6
% samples each - one for each target
vt_ds=cosmo_fx(vt_ds, @(x)mean(x,1), 'targets', 1);
ev_ds=cosmo_fx(ev_ds, @(x)mean(x,1), 'targets', 1);


% remove constant features
vt_ds=cosmo_remove_useless_data(vt_ds);
ev_ds=cosmo_remove_useless_data(ev_ds);

% Use pdist (or cosmo_pdist) with 'correlation' distance to get DSMs
% >@@>
ev_dsm = pdist(ev_ds.samples, 'correlation');
vt_dsm = pdist(vt_ds.samples, 'correlation');
% <@@<

% Using matlab's subplot function place the heat maps for EV and VT DSMs side by
% side in the top two positions of a 3 x 2 subplot figure

% >@@>
figure();

subplot(3,2,1);
imagesc(squareform(ev_dsm));
title('EV');

subplot(3,2,2);
imagesc(squareform(vt_dsm));
title('VT');
% <@@<



% Now add the dendrograms for EV and LV in the middle row of the subplot figure
% (this requires matlab's stats toolbox)
labels = {'monkey','lemur','mallard','warbler','ladybug','lunamoth'}';
%
% First, compute the linkage using Matlab's linkage. Assign the result
% to 'ev_hclus' and 'vt_hclus'

ev_hclus = linkage(ev_dsm);
vt_hclus = linkage(vt_dsm);
% <@@<

% skip if stats toolbox is not present
if cosmo_check_external('@stats',false)
    subplot(3,2,3);
    % show dendogram of 'ev_hclus'
    % Asa additional argument to the dendogram function, use:
    %      'labels',labels,'orientation','left'
    % >@@>
    dendrogram(ev_hclus,'labels',labels,'orientation','left');
    % <@@<

    % Along the same way, show a dendogram of 'vt_hclus'
    subplot(3,2,4);
    % >@@>
    dendrogram(vt_hclus,'labels',labels,'orientation','left');
    % <@@<
else
    fprintf('stats toolbox not present; cannot show dendrograms\n');
end

% Show the the MDS plots in the bottom row

% Show early visual cortex model similarity
F_ev = cmdscale(squareform(ev_dsm));
subplot(3,2,5);
text(F_ev(:,1), F_ev(:,2), labels);
mx = max(abs(F_ev(:)));
xlim([-mx mx]);
ylim([-mx mx]);

% Show VT similarity
% >@@>
F_vt = cmdscale(squareform(vt_dsm));
subplot(3,2,6);
text(F_vt(:,1), F_vt(:,2), labels);
mx = max(abs(F_vt(:)));
xlim([-mx mx]);
ylim([-mx mx]);
% <@@<

