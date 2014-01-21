%% Dataset basics
% Set data path, load dataset, set targets and chunks, and add labels as
% sample attributes

% Set the data path 
config=cosmo_config();
data_path=fullfile(config.data_path,'ak6','s01');

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
ds

%% Overview of sample attributes
ds.sa

% print targets and chunks
[ds.sa.targets ds.sa.chunks]

% print labels
ds.sa.labels

%% Overview of feature attributes
ds.fa

% print a few voxel indices
ijk_indices=[ds.fa.i(:,1:10); ds.fa.j(:,1:10); ds.fa.k(:,1:10)];
ijk_indices
