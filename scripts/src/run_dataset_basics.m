% Dataset basics
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
%
% There are 10 runs with 6 volumes per run. The runs are vertically stacked one
% above the other. The six volumes in each run correspond to the stimuli:
% 'monkey','lemur','mallard','warbler','ladybug','lunamoth', in that order. Add
% numeric targets labels (samples atribute) such that 1 corresponds to 'monkey',
% 2 corresponds to 'lemur', etc. Then add numeric chunks (another samples
% attribute) so that 1 corresponds to run1, 2 corresponds to run2, etc.

%>>
ds.sa.targets = repmat([1:6]',10,1); chunks = []; for i=1:10 chunks = [chunks;
repmat(i,6,1)]; end ds.sa.chunks = chunks;
% <<


