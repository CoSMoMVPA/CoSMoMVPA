%% Dataset Basics
% Load datasets using cosmo_fmri_dataset
%
% This function loads data stored in a nifti file and return a dataset struct
% where the data are store in the 2-D array in field dataset.samples
%
% For each of the three masks ('brain','ev','vt'), 
% print the number of voxels when loading the dataset with that mask.
%
% Hint: the number of voxels is given by the number of columns in
% dataset.samples

%% Set the datapath
% 

config=cosmo_config();
data_path=fullfile(config.data_path,'ak6','s01');

%% Compute number of voxels in each mask
% First load data with full brain mask

% >>
ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii'], ...
                        'mask', [data_path '/brain_mask.nii']);
[nsamples, nfeatures] = size(ds.samples);
% <<

fprintf('There are %d voxels in the whole brain mask\n', nfeatures);

% Now do the same with the EV and VT masks.

% >>
ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii'], ...
                        'mask', [data_path '/ev_mask.nii']);
[nsamples, nfeatures] = size(ds.samples);

fprintf('There are %d voxels in the EV mask\n', nfeatures);

ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii'], ...
                        'mask', [data_path '/vt_mask.nii']);
[nsamples, nfeatures] = size(ds.samples);

fprintf('There are %d voxels in the VT mask\n', nfeatures);
% <<
