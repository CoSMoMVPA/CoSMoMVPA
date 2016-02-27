%% Dataset Basics
% Load datasets using cosmo_fmri_dataset
%
% This function loads data stored in a nifti file and return a dataset struct
% where the data are stored in the 2-D array in field dataset.samples
%
% For each of the three masks ('brain','ev','vt'),
% print the number of voxels when loading the dataset with that mask.
%
% Hint: the number of voxels is given by the number of columns in
% dataset.samples
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

%% Set the datapath
%
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

%% Compute number of voxels in each mask
% Hints:
% -In order not to get overwhelmed, solve a simple problem first and then
% generalize from it.
%   -First write some code in which you load data with full brain mask.
% Generalization:
%   -Next, you could just copy and alter that code such that you do the
%   same thing with the other masks
%   -A more elegant solution would be to put the three mask names into a
%   cell array and to write a loop that performs the same set of operations
%   on the members of the cell array (i.e. the three different mask names

% Let's start with the simple approach.
% Set the filename
% >@@>
mask_fn = fullfile(data_path, 'brain_mask.nii');
% <@@<

% Load the dataset and store in struct 'ds'
% >@@>
ds=cosmo_fmri_dataset(mask_fn);
% <@@<

% Compute number of features that are greater than zero
% hint: use ds.samples
nfeatures=sum(ds.samples>0);

fprintf('There are %d voxels in the whole brain mask\n', nfeatures);
% <@@<

% Now do the same with the EV and VT masks.
% >@@>
mask_fn = fullfile(data_path, 'vt_mask.nii');
ds=cosmo_fmri_dataset(mask_fn);
nfeatures=sum(ds.samples>0);

fprintf('There are %d voxels in the ventral-temporal mask\n', nfeatures);

mask_fn = fullfile(data_path, 'ev_mask.nii');
ds=cosmo_fmri_dataset(mask_fn);
nfeatures=sum(ds.samples>0);
fprintf('There are %d voxels in the early-visual brain mask\n', nfeatures);

% <@@<
%
% And here is space for the more elegant solution in which you define a
% list of mask names and apply the operation in a loop for all masks in the
% list
maskNames = {'brain_mask.nii', 'vt_mask.nii', 'ev_mask.nii'};
data_fn = fullfile(data_path, 'glm_T_stats_perrun.nii');

for iMask=1:numel(maskNames)
    % >@@>
    mask_fn=fullfile(data_path, maskNames{iMask});
    ds=cosmo_fmri_dataset(mask_fn);
    nfeatures=sum(ds.samples>0);
    fprintf('There are %6d voxels in the mask ''%s''\n', nfeatures, maskNames{iMask});
    % <@@<
end
