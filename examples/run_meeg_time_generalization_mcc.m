%% MEEG time generalization multiple comparison correction
% This example shows MVPA analyses performed on MEEG data.
%
% The input dataset involved a paradigm where a participant saw
% images of six object categories.
%
% The code presented here can be adapted for other MEEG analyses, but
% there please note:
% * the current examples do not perform baseline corrections or signal
%   normalizations, which may reduce discriminatory power.
%
% Note: running this code requires FieldTrip.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

%% get timelock data in CoSMoMVPA format

% set configuration
config = cosmo_config();
data_path = fullfile(config.tutorial_data_path, 'meg_obj6');

% show dataset information
readme_fn = fullfile(data_path, 'README');
cosmo_type(readme_fn);

% reset citation list
cosmo_check_external('-tic');

% load preprocessed data
data_fn = fullfile(data_path, 'meg_obj6_s00.mat');
data_tl = load(data_fn);

% convert to cosmomvpa struct and show the dataset
ds = cosmo_meeg_dataset(data_tl);
cosmo_disp(ds);

% set the targets (trial condition)
ds.sa.targets = ds.sa.trialinfo(:, 1); % 6 categories

% set the chunks (independent measurements)
% all trials are here considered to be independent
nsamples = size(ds.samples, 1);
ds.sa.chunks = (1:nsamples)';

% in addition give a label to each trial
index2label = {'body', 'car', 'face', 'flower', 'insect', 'scene'};
ds.sa.labels = cellfun(@(x)index2label(x), num2cell(ds.sa.targets));

% just to check everything is ok
cosmo_check_dataset(ds);

%% Select subset of sensors and time points

% Select posterior gradiometers
sensor_posterior_planar = {'MEG1632', 'MEG1642', 'MEG1732', 'MEG1842', ...
                           'MEG1912', 'MEG1922', 'MEG1942', 'MEG2232', ...
                           'MEG2312', 'MEG2322', 'MEG2342', 'MEG2432', ...
                           'MEG2442', 'MEG2512', 'MEG2532', ...
                           'MEG1633', 'MEG1643', 'MEG1733', 'MEG1843', ...
                           'MEG1913', 'MEG1923', 'MEG1943', 'MEG2233', ...
                           'MEG2313', 'MEG2323', 'MEG2343', 'MEG2433', ...
                           'MEG2443', 'MEG2513', 'MEG2533'};

msk = cosmo_dim_match(ds, 'chan', sensor_posterior_planar, ...
                      'time', @(t)t >= 0 & t <= .3);

ds_sel = cosmo_slice(ds, msk, 2);
ds_sel = cosmo_dim_prune(ds_sel);

%%
% subsample time dimension to speed up the analysis
subsample_time_factor = 3; % take every 3rd time point

% take every subsample_time_factor-th
% hint: use ds.fa.time to find the desired features, then use cosmo_slice
% and cosmo_dim_prune.
% >@@>
msk = mod(ds_sel.fa.time, subsample_time_factor) == 1;
ds_sel = cosmo_slice(ds_sel, msk, 2);
ds_sel = cosmo_dim_prune(ds_sel);
% <@@<

% to illustrate group analysis, we use data from a single participant
% and divide it in ten parts. Each part represents a pseudo-participant.
n_pseudo_participants = 10;
ds_sel.sa.subject_id = cosmo_chunkize(ds_sel, n_pseudo_participants);
ds_cell = cosmo_split(ds_sel, 'subject_id');

%%
% apply the cosmo_dim_generalization_measure to the data from each
% pseudo-participant
group_cell = cell(n_pseudo_participants, 1);

for k = 1:n_pseudo_participants
    ds_subj = ds_cell{k};
    ds_subj.sa = rmfield(ds_subj.sa, 'subject_id');

    ds_subj = cosmo_balance_dataset(ds_subj);
    ds_subj.sa.chunks = cosmo_chunkize(ds_subj, 2);
    ds_subj_tr = cosmo_dim_transpose(ds_subj, 'time', 1);

    % use a custom measure that computes a one-way ANOVA F-value and
    % then converts this to a z-score
    measure = @(d, opt)cosmo_stat(d, 'F', 'z');

    ds_time_gen = cosmo_dim_generalization_measure(ds_subj_tr, ...
                                                   'measure', @cosmo_correlation_measure, ...
                                                   'dimension', 'time');

    group_cell{k} = ds_time_gen;
end

%%
% show an element of group_cell. What is the size of .samples?
cosmo_disp(group_cell{1});

%%
% To do group analysis, the above format will not work.
% We want a dataset ds_group with size n_pseudo_participants x NF
% where NF is the number of features.

% allocate a cell group_cell_tr with the same size of group_cell
% >@@>
group_cell_tr = cell(size(group_cell));
% <@@<

for k = 1:numel(group_cell)
    % take data from the k-th participant and store
    % in a varibale ds_time_gen
    ds_time_gen = group_cell{k};

    % change 'train_time' and 'test_time' from being sample dimensions
    % to become feature dimensions.
    % Hint: use cosmo_dim_transpose.
    % >@@>
    ds_time_gen_tr = cosmo_dim_transpose(ds_time_gen, ...
                                         {'train_time', 'test_time'}, 2);
    % <@@<

    % set chunks and targets for a one-sample t-test against zero,
    % so that across participants: all targets have the same value, and
    % all chunks have different values.
    % >@@>
    ds_time_gen_tr.sa.chunks = k;
    ds_time_gen_tr.sa.targets = 1;
    % <@@<

    % store ds_time_gen_tr as the k-th element in group_cell_tr
    % >@@>
    group_cell_tr{k} = ds_time_gen_tr;
    % <@@<
end

% show an element of group_cell_tr. What is the size of .samples?
cosmo_disp(group_cell_tr{1});

%%
% stack the elements in group_cell_tr into a dataset ds_group
% >@@>
ds_group = cosmo_stack(group_cell_tr);
% <@@<

%%
% define a clustering neighborhood and store the result in a struct
% called nbrhood
% Hint: use cosmo_cluster_neighborhood
nbrhood = cosmo_cluster_neighborhood(ds_group);

%%

% run multiple comparison correction using cosmo_montecarlo_cluster_stat
% with 1000 iterations, for a t-test against h0_mean=0.
opt = struct();
opt.niter = 1000;
opt.h0_mean = 0;
ds_tfce = cosmo_montecarlo_cluster_stat(ds_group, nbrhood, opt);

%%
% >@@>
ds_group = cosmo_stack(group_cell_tr);
% <@@<

% extract the values from the ds_tfce, using cosmo_unflatten.
% store the array, and the dimension labels and values, into variables
% arr, dim_labels, and dim_values.
% Hint: use cosmo_unflatten.
% >@@>
[arr, dim_labels, dim_values] = cosmo_unflatten(ds_tfce);
% <@@<

% Reshape to arr to be 2-dimensional and store the result in arr_2d,
% then visualize the array
% >@@>
arr_2d = squeeze(arr);
% <@@<
clim = [-1, 1] * max(abs(arr_2d(:)));
imagesc(arr_2d, clim);

% add axis labels
nticks = 5;

ytick = round(linspace(1, numel(dim_values{1}), nticks));
ylabel(strrep(dim_labels{1}, '_', ' '));
set(gca, 'Ytick', ytick, 'YTickLabel', dim_values{1}(ytick));

xtick = round(linspace(1, numel(dim_values{2}), nticks));
xlabel(strrep(dim_labels{2}, '_', ' '));
set(gca, 'Xtick', xtick, 'XTickLabel', dim_values{2}(xtick));
colorbar();

% bonus: add markers indicating significance
% >@@>
z_min = 1.96;
[i, j] = find(abs(arr_2d) > z_min);
hold on;
scatter(j, i, 'o', 'k');
hold off;
% <@@<
