%% Dataset Basics (setting sample attributes)
%
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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

%% Load the dataset 'glm_T_stats_perrun.nii' masked with 'brain_mask.nii'
% >@@>
mask_fn = fullfile(data_path, 'brain_mask.nii');
data_fn = fullfile(data_path, 'glm_T_stats_perrun.nii');
ds=cosmo_fmri_dataset(data_fn, 'mask', mask_fn);
% <@@<
%% set targets
%remember that targets are part of ds.sa and that they are stored in a
%column vector
% >@@>
ds.sa.targets = repmat(1:6, [1, 10])'; %10 times labels 1 to 6, column vector
% <@@<
%% set chunks
%remember that chunks are part of ds.sa and that they are stored in a
%column vector
% >@@>
chunks = repmat(1:10, [6, 1]);
chunks = chunks(:); %flatten matrix to a column vector
ds.sa.chunks = chunks;
% <@@<

%% Show the results

%% print the dataset
fprintf('\nDataset:\n')
cosmo_disp(ds)

%% print the sample attributes
fprintf('\nSample attributes (in full):\n')
cosmo_disp(ds.sa,'edgeitems',Inf); %'edgeitems determine how much of a
                                   % matrix is displayed. Try different values.

%% print targets and chunks next to each other
fprintf('\nTargets and chunks attributes (in full):\n')
nsamples=size(ds.samples,1);
fprintf('sample #   target   chunk\n');
index_target_chunks=[(1:nsamples)', ds.sa.targets,ds.sa.chunks];
cosmo_disp(index_target_chunks,'edgeitems',Inf);
