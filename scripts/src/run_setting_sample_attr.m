%% Dataset Basics
% Set the targets and the chunks
%
% There are 10 runs with 6 volumes per run. The runs are vertically stacked one
% above the other. The six volumes in each run correspond to the stimuli:
% 'monkey','lemur','mallard','warbler','ladybug','lunamoth', in that order. Add
% numeric targets labels (samples atribute) such that 1 corresponds to 'monkey',
% 2 corresponds to 'lemur', etc. Then add numeric chunks (another samples
% attribute) so that 1 corresponds to run1, 2 corresponds to run2, etc.

% >>

ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii.gz'], ...
                        'mask', [data_path '/brain_mask.nii.gz']);

% set targets
ds.sa.targets = repmat([1:6]',10,1); 

% set chunks
chunks = []; 
for i=1:10 chunks = [chunks; repmat(i,6,1)]; end 
ds.sa.chunks = chunks;
% <<


