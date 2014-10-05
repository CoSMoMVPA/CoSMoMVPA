%% Dataset basics
% Set data path, load dataset, set targets and chunks, and add labels as
% sample attributes

% Set the data path
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% >@@>
fn=fullfile(data_path,'glm_T_stats_perrun.nii');
ds = cosmo_fmri_dataset(fn);

% <@@<

% set ds.sa.targets (trial conditions) to the 60x1 column vector:
% [ 1 2 3 4 5 6 1 2 3 ... 5 6 ]'
% >@@>
targets=repmat([1:6]',10,1);
ds.sa.targets = targets;
% <@@<

% set ds.sa.chunks (acquistion run number) to the 60x1 column vector:
% [ 1 1 1 1 1 1 2 2 2 ... 10 10 ]'
% >@@>
chunks = zeros(60,1);
for i=1:10
    idxs=(i-1)*6+(1:6);
    chunks(idxs)=i;
end
ds.sa.chunks = chunks;
% <@@<

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
% 2 to indicate the slicing of features (not samples)
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


%% Various slicing operations on the samples

% only get data in chunks 1 and 2.
% Make a logical mask indicating where .ds.chunks less than or equal to 2,
% then use cosmo_slice to select these samples
% (hint: you can use cosmo_match or just '<=')
% >@@>
chunks12_msk=ds.sa.chunks<=2;
ds_chunks12=cosmo_slice(ds_masked,chunks12_msk);
cosmo_disp(ds_chunks12);
% <@@<

% only get data in conditions 1 and 3
% >@@>
% (there are multiple ways of doing this)
targets_13=ds.sa.targets==1 | ds.sa.targets==3; % element-wise logical 'or'
ds_targets13=cosmo_slice(ds_masked,targets_13);
cosmo_disp(ds_targets13);

targets_13_alt=cosmo_match(ds.sa.targets,[1 3]); % using cosmo_match
ds_targets13_alt=cosmo_slice(ds_masked,targets_13_alt);
cosmo_disp(ds_targets13_alt);

% sanity check showing they are the same
assert(isequal(ds_targets13,ds_targets13_alt));

% alterative using cosmo_match and the labels
labels_monkey_or_mallard=cosmo_match(ds.sa.labels,{'monkey','mallard'});
ds_targets13_alt2=cosmo_slice(ds_masked,labels_monkey_or_mallard);
cosmo_disp(ds_targets13_alt2);

% sanity check showing they are the same
assert(isequal(ds_targets13,ds_targets13_alt2));
% <@@<
