%% Dataset Basics
% Run operations on datasets
%

%% Load data and set targets
% Load data as before setting targets and chunks appropriately

config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');
mask_fn = fullfile(data_path, 'vt_mask.nii');
data_fn = fullfile(data_path, 'glm_T_stats_perrun.nii');
ds=cosmo_fmri_dataset(data_fn, 'mask', mask_fn);

% set ds.sa.targets (trial conditions) to the 60x1 column vector:
% [ 1 2 3 4 5 6 1 2 3 ... 5 6 ]'
% >@@>
ds.sa.targets = repmat((1:6)',10,1);
% <@@<

% set ds.sa.chunks (acquistion run number) to the 60x1 column vector:
% [ 1 1 1 1 1 1 2 2 2 ... 10 10 ]'
% >@@>
chunks = repmat(1:10, [6, 1]);
chunks = chunks(:);
ds.sa.chunks = chunks;
% <@@<

% This particular ROI has a few constant features due to
% not-so-agressive masking, so remove constant features
ds=cosmo_remove_useless_data(ds);

%% Set the sample indices that correspond to primates and bugs

% >@@>
primate_idx = ds.sa.targets <= 2;
bug_idx = ds.sa.targets > 4;
% <@@<



%% Slice the dataset
% use the indices as input to cosmo_slice

% >@@>
primate_ds = cosmo_slice(ds, primate_idx);
bug_ds = cosmo_slice(ds, bug_idx);
% <@@<

%% Subtract mean pattern
% Find the mean pattern for primates and bugs and subtract the bug pattern from
% the primate pattern

% >@@>
primates_mean = mean(primate_ds.samples, 1);
bugs_mean = mean(bug_ds.samples, 1);
primates_minus_bugs = primates_mean - bugs_mean;
% <@@<

%% Store and visualize the results
% Finally save the result as a dataset with the original header.
% Just replace ds.samples with the result and remove the sample attributes.
% Then convert back to nifti and save it using cosmo_map2fmri function.

% >@@>
ds_primates_minus_bugs=ds; % make a copy
ds_primates_minus_bugs.samples = primates_minus_bugs;
ds_primates_minus_bugs.sa=struct();
cosmo_check_dataset(ds_primates_minus_bugs); %good practice

% store to disc
output_fn=fullfile(data_path, 'primates_minus_bugs.nii');
ni = cosmo_map2fmri(ds_primates_minus_bugs, output_fn);
% <@@<

%% Plot results
figure
%... using cosmo_plot_slices

% >@@>
cosmo_plot_slices(ds_primates_minus_bugs)
% <@@<

% ... using AFNI, FSL, or Matlab's imagesc
figure

% >@@>
imagesc(rot90(ni.img(:,:,4)));
title('Primates minus Bugs')
box off
ylabel('P <-  y  ->  A'),
xlabel('L <-  x  ->  R')
% <@@<
