%% Dataset Basics
% Set the targets and the chunks
%
% There are 10 runs with 6 volumes per run. The runs are vertically stacked one
% above the other. The six volumes in each run correspond to the stimuli:
% 'monkey','lemur','mallard','warbler','ladybug','lunamoth', in that order. Add
% numeric targets labels (samples atribute) such that 1 corresponds to 'monkey',
% 2 corresponds to 'lemur', etc. Then add numeric chunks (another samples
% attribute) so that 1 corresponds to run1, 2 corresponds to run2, etc.

config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

%% Load the dataset
% >@@>

ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii'], ...
                        'mask', [data_path '/brain_mask.nii']);
% <@@<
%% set targets
% >@@>
ds.sa.targets = repmat([1:6]',10,1); 
% <@@<
%% set chunks
% >@@>
ds.sa.chunks = floor(((1:60)-1)/6)'+1;
% <@@<

%% Show the results

%% print the dataset
fprintf('\nDataset:\n')
cosmo_disp(ds)

%% print the sample attributes
fprintf('\nSample attributes (in full):\n')
cosmo_disp(ds.sa,'edgeitems',Inf);

%% print targets and chunks next to each other
fprintf('\nTargets and chunks attributes (in full):\n')
nsamples=size(ds.samples,1);
fprintf('sample #   target   chunk\n');
index_target_chunks=[(1:nsamples)', ds.sa.targets,ds.sa.chunks];
cosmo_disp(index_target_chunks,'edgeitems',Inf);
