%% Dataset basics
% Set data path, load dataset, set targets and chunks, and add labels as
% sample attributes

% Set the data path (change cosmo_get_data_path if necessary)
data_path=cosmo_get_data_path('s01');

% Load dataset (and supply a mask file for 'vt')
% >>
ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii.gz'], ...
                         'mask', [data_path '/vt_mask.nii.gz']);
% <<

% Set the targets and the chunks
% >>
ds.targets = repmat([1:6]',10,1)';
chunks = []; for i=1:10 chunks = [chunks repmat(i,6,1)]; end
ds.chunks = chunks;
% <<

% Add labels as sample attributes
% >>
<<<<<<< HEAD:scripts/src/run_dataset_basics.m
labels = {'monkey','lemur','mallard','warbler','ladybug','lunamoth'};
ds.sa.labels = repmat(labels,1,10)
% <<
=======
labels = {'monkey','lemur','mallard','warbler','ladybug','lunamoth'}';
ds.sa.labels = repmat(labels,10,1)
% <<
>>>>>>> 868ef13bd03f668a468b65de5258afe8d4bddfc9:scripts/src/run_dataset_basics.m
