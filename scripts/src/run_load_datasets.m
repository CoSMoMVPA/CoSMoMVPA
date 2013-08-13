%% Dataset Basics
% Load datasets using cosmo_fmri_dataset
%
% This function loads data stored in a nifti file and return a dataset struct
% where the data are store in the 2-D array in field dataset.samples
%
% Hint: the number of voxels is given by the number of columns in
% dataset.samples

% First load data with full brain mask

% >>
ds = cosmo_fmri_dataset([data_path '/glm_T_stats_allruns.nii.gz'], ...
                        'mask', [data_path '/brain_mask.nii.gz']);
[nsamples, nfeatures] = size(ds.samples);
% <<

% Answer: There are X voxels in the whole brain mask.

% Now do the same with the EV and VT masks.

% >>
ds = cosmo_fmri_dataset([data_path '/glm_T_stats_allruns.nii.gz'], ...
                        'mask', [data_path '/ev_mask.nii.gz']);
[nsamples, nfeatures] = size(ds.samples);

% There are X voxels in the EV mask.

ds = cosmo_fmri_dataset([data_path '/glm_T_stats_allruns.nii.gz'], ...
                        'mask', [data_path '/vt_mask.nii.gz']);
[nsamples, nfeatures] = size(ds.samples);

% There are X voxels in the VT mask.
% <<
