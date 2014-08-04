%% Dataset basics
% Set data path, load dataset, set targets and chunks, and add labels as
% sample attributes

% Set the data path
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% Load dataset (and supply a mask file for 'vt')
% >@@>
ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii'], ...
                         'mask', [data_path '/vt_mask.nii']);
% <@@<

% Set the targets and the chunks
% >@@>
ds.sa.targets = repmat([1:6]',10,1);
chunks = []; for i=1:10 chunks = [chunks; repmat(i,6,1)]; end
ds.sa.chunks = chunks;
% <@@<

% Add labels as sample attributes
% >@@>
labels = {'monkey','lemur','mallard','warbler','ladybug','lunamoth'}';
ds.sa.labels = repmat(labels,10,1);
% <@@<

%% Overview of the dataset
fprintf('\nOverview of dataset:\n');
cosmo_disp(ds)

%% Overview of sample attributes (targets, chunks, and labels, in this case):
fprintf('\nOverview of sample attributes\n');
cosmo_disp(ds.sa,'edgeitems',10)

%% Overview of feature attributes (the voxel indices, in this case):
fprintf('\nOverview of feature attributes\n');
cosmo_disp(ds.fa,'edgeitems',10)
