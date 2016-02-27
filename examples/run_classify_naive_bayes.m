%% Two-class classification with naive baysian classifier
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

%% Define data
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% Load the dataset with VT mask
ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii'], ...
                     'mask', [data_path '/vt_mask.nii']);

% remove constant features
ds=cosmo_remove_useless_data(ds);

%% set the targets and chunks
ds.sa.targets = repmat((1:6)',10,1);
ds.sa.chunks = floor(((1:60)-1)/6)'+1;

% Add labels as sample attributes
labels = {'monkey','lemur','mallard','warbler','ladybug','lunamoth'};
ds.sa.labels = repmat(labels,1,10)';

% get indices for monkeys and mallards
idx = strcmp(ds.sa.labels,'monkey') | strcmp(ds.sa.labels,'mallard');

%% Slice the dataset
% Use sample attrubutes slicer to slice dataset
ds2 = cosmo_slice(ds,idx);

% slice into odd and even runs using chunks attribute
even_idx = mod(ds2.sa.chunks,2)==0;
odd_idx = mod(ds2.sa.chunks,2)==1;

evens = cosmo_slice(ds2,even_idx);
odds = cosmo_slice(ds2, odd_idx);

%% train on even, test on odd
pred = cosmo_classify_naive_bayes(evens.samples, evens.sa.targets, odds.samples);
accuracy = mean(odds.sa.targets == pred);
fprintf('Train on even, test on odd: accuracy %.3f\n', accuracy);
% Answer: accuracy should be .70

%% train on odd, test on even
pred = cosmo_classify_naive_bayes(odds.samples, odds.sa.targets,evens.samples);
accuracy = mean(evens.sa.targets == pred);
fprintf('Train on odd, test on even: accuracy %.3f\n', accuracy);
% Answer: accuracy = .60


