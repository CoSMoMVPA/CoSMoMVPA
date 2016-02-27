%% Demo: fMRI searchlight with naive bayes classifier
%
% The data used here is available from http://cosmomvpa.org/datadb.zip
%
% This example uses the following dataset:
% + 'digit'
%    A participant made finger pressed with the index and middle finger of
%    the right hand during 4 runs in an fMRI study. Each run was divided in
%    4 blocks with presses of each finger and analyzed with the GLM,
%    resulting in 2*4*4=32 t-values
%
% This example uses the cosmo_naive_bayes_classifier_searchlight, which is
% a fast alternative to using the regular searchlight with a
% crossvalidation measure and a classifier
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #



%% Set data paths
% The function cosmo_config() returns a struct containing paths to tutorial
% data. (Alternatively the paths can be set manually without using
% cosmo_config.)
config=cosmo_config();

digit_study_path=fullfile(config.tutorial_data_path,'digit');
readme_fn=fullfile(digit_study_path,'README');
cosmo_type(readme_fn);

output_path=config.output_data_path;

% reset citation list
cosmo_check_external('-tic');

%% LDA classifier searchlight analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This analysis identified brain regions where the categories can be
% distinguished using an odd-even partitioning scheme and a Naive Bayes
% classifier.

data_path=digit_study_path;
data_fn=fullfile(data_path,'glm_T_stats_perblock+orig.HEAD');
mask_fn=fullfile(data_path,'brain_mask+orig.HEAD');

targets=repmat(1:2,1,16)';    % class labels: 1 2 1 2 1 2 1 2 1 2 ... 1 2
chunks=floor(((1:32)-1)/8)+1; % run labels:   1 1 1 1 1 1 1 1 2 2 ... 4 4

ds_per_run = cosmo_fmri_dataset(data_fn, 'mask', mask_fn,...
                                'targets',targets,'chunks',chunks);

% print dataset
fprintf('Dataset input:\n');
cosmo_disp(ds_per_run);


% set parameters for naive bayes searchlight (partitions) in a
% measure_args struct.
measure_args = struct();

% Set partition scheme. odd_even is fast; for publication-quality analysis
% nfold_partitioner is recommended.
% Alternatives are:
% - cosmo_nfold_partitioner    (take-one-chunk-out crossvalidation)
% - cosmo_nchoosek_partitioner (take-K-chunks-out  "             ").
measure_args.partitions = cosmo_oddeven_partitioner(ds_per_run);

% print measure and arguments
fprintf('Searchlight measure arguments:\n');
cosmo_disp(measure_args);

% Define a neighborhood with approximately 100 voxels in each searchlight.
nvoxels_per_searchlight=100;
nbrhood=cosmo_spherical_neighborhood(ds_per_run,...
                        'count',nvoxels_per_searchlight);


%% Run the searchlight
%
nb_results = cosmo_naive_bayes_classifier_searchlight(ds_per_run,...
                                                nbrhood,measure_args);
%% Show results
% print output dataset
fprintf('Dataset output:\n');
cosmo_disp(nb_results);

% Plot the output
cosmo_plot_slices(nb_results);

% Define output location
output_fn=fullfile(output_path,'naive_bayes_searchlight+orig');

% Store results to disc
cosmo_map2fmri(nb_results, output_fn);

% Show citation information
cosmo_check_external('-cite');
