%% Dataset Basics
% Run operations on datasets
%

%% Load data and set targets
% Load data as before setting targets and chunks appropriately

config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% >@@>
ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii'], ...
                        'mask', [data_path '/vt_mask.nii']);

% set targets
ds.sa.targets = repmat([1:6]',10,1);

% set chunks
% equivalent code would be:
%   chunks=zeros(60,1);
%   for k=1:10
%       chunks((k-1)*6+(1:6))=k;
%   end
ds.sa.chunks=floor(((1:60)-1)'/6)+1;

% <@@<

% remove constant features
ds=cosmo_remove_useless_data(ds);

%% Set the sample indices that correspond to primates and bugs

% >@@>
primate_idx = ds.sa.targets <= 2;
bug_idx = ds.sa.targets > 4;
% <@@<

%% Slice the dataset
% use the indices as input to the dataset slicer

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
% Finally save the result as a dataset with the original header
% Just replace ds.samples with the result and remove the sample attributes.
% Then convert back to nifti and save it using cosmo_map2fmri function.

% >@@>
ds.samples = primates_minus_bugs;
ds.sa=struct();
ni = cosmo_map2fmri(ds, [data_path '/primates_minus_bugs.nii']);

% View the result using AFNI, FSL, or Matlab's imagesc

imagesc(ni.img(:,:,4));

% <@@<

%% Plot slices using cosmo_plot_slices
cosmo_plot_slices(ni.img)
