%% Dataset basics
% Load the dataset with VT mask
data_path=cosmo_get_data_path('s01');

ds = fmri_dataset([data_path '/glm_T_stats_perrun.nii.gz'], ...
                    'mask', [data_path '/vt_mask.nii.gz']);

% set the targets and the chunks
ds.targets = repmat([1:6],1,10);
chunks = []; for i=1:10 chunks = [chunks repmat(i,1,6)]; end
ds.chunks = chunks;

% Add labels as sample attributes
labels = {'monkey','lemur','mallard','warbler','ladybug','lunamoth'};
ds.sa.labels = repmat(labels,1,10)