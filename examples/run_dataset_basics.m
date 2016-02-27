%% Dataset basics
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

% Set data path, load dataset, set targets and chunks, and add labels as
% sample attributes

% Set the data path
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% Set the filename to the glm_T_stats_perrun NIFTI file
% >@@>
fn=fullfile(data_path,'glm_T_stats_perrun.nii');
% <@@<

% >@@>
% Load data using cosmo_fmri_dataset
ds = cosmo_fmri_dataset(fn);
% <@@<

% set ds.sa.targets (trial conditions) to the 60x1 column vector:
% [ 1 2 3 4 5 6 1 2 3 ... 5 6 ]'
% >@@>
targets=repmat((1:6)',10,1);
ds.sa.targets = targets;
% <@@<

% sanity check
cosmo_check_dataset(ds);

% set ds.sa.chunks (acquistion run number) to the 60x1 column vector:
% [ 1 1 1 1 1 1 2 2 2 ... 10 10 ]'
% >@@>
chunks = zeros(60,1);
for i=1:10
    idxs=(i-1)*6+(1:6);
    chunks(idxs)=i;
end
ds.sa.chunks = chunks;

% ( alternative:   ds.sa.chunks = ceil((1:60)'/6);     )
% <@@<

% sanity check
cosmo_check_dataset(ds);

% Add ds.sa.labels as sample attributes as a 60x1 cell with strings
% The order is {monkey, lemur, mallard, warbler, ladybug, and lunamoth},
% repeated 10 times
% >@@>
labels = repmat({   'monkey';
                    'lemur';
                    'mallard';
                    'warbler';
                    'ladybug';
                    'lunamoth'},10,1);
ds.sa.labels = labels;
% <@@<

% sanity check
cosmo_check_dataset(ds);

%% Overview of the dataset
fprintf('\nOverview of dataset:\n');
cosmo_disp(ds)

%% Apply mask to dataset
fn_mask=fullfile(data_path,'vt_mask.nii');

% Load mask using cosmo_fmri_dataset and store in ds_mask
% >@@>
ds_mask=cosmo_fmri_dataset(fn_mask);
% <@@<

% sanity check: ensure the same feature attributes
assert(isequal(ds_mask.fa,ds.fa));

% Now slice the dataset using cosmo_slice, where the third argument must be
% 2 to indicate the slicing of features (not samples).
% Assign the result to a variable 'ds_masked'.
% >@@>
mask_indices=find(ds_mask.samples);
ds_masked=cosmo_slice(ds, mask_indices, 2);
cosmo_disp(ds_masked);
% <@@<

%% Now use cosmo_fmri_dataset with all input parameters

% We do exactly the same as above, but shorter:
% Load the dataset again using cosmo_fmri_dataset, but now use the
% 'mask','targets','chunks' parameters.
% Assign the result to ds_masked_alt
% >@@>
ds_masked_alt=cosmo_fmri_dataset(fn,'mask',fn_mask,...
                                'targets',targets,...
                                'chunks',chunks);
% <@@<

% set labels again
ds_masked_alt.sa.labels=labels;

% check ds_masked and ds_masked_alt are the same
assert(isequal(ds_masked_alt,ds_masked));
