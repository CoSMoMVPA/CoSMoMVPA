%% Demo: Threshold-Free Cluster Enhancement (TFCE) on surface dataset
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
% This example illustrates the use of Threshold-Free Cluster Enhancement
% with a permutation test to correct for multiple comparisons.
%
% TFCE reference: Stephen M. Smith, Thomas E. Nichols, Threshold-free
% cluster enhancement: Addressing problems of smoothing, threshold
% dependence and localisation in cluster inference, NeuroImage, Volume 44,
% Issue 1, 1 January 2009, Pages 83-98.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

%% Check externals
cosmo_check_external({'surfing','afni'});

%% Set data paths
% The function cosmo_config() returns a struct containing paths to tutorial
% data. (Alternatively the paths can be set manually without using
% cosmo_config.)
config=cosmo_config();

digit_study_path=fullfile(config.tutorial_data_path,'digit');
readme_fn=fullfile(digit_study_path,'README');
cosmo_type(readme_fn);

output_path=config.output_data_path;

% resolution parameter for input surfaces
% 64 is for high-quality results; use 16 for fast execution
ld=16;

% reset citation list
cosmo_check_external('-tic');

% load single surface
intermediate_fn=fullfile(digit_study_path,...
                            sprintf('ico%d_mh.intermediate_al.asc', ld));
[vertices,faces]=surfing_read(intermediate_fn);


%% Load functional data
data_path=digit_study_path;
data_fn=fullfile(data_path,'glm_T_stats_perblock+orig');

targets=repmat(1:2,1,16)';    % class labels:  1 2 1 2 1 2 1 2 1 2 ... 1 2
chunks=floor(((1:32)-1)/4)+1; % half-run:      1 1 1 1 2 2 2 2 3 3 ... 8 8

vol_ds = cosmo_fmri_dataset(data_fn,'targets',targets,'chunks',chunks);

%% Map univariate response data to surface

% this measure averages the data near each node to get a surface dataset
radius=0;
surf_band_range=[-2 2]; % get voxel data within 2mm from surface
surf_def={vertices,faces,[-2 2]};
nbrhood=cosmo_surficial_neighborhood(vol_ds,surf_def,'radius',radius);

measure=@(x,opt) cosmo_structjoin('samples',mean(x.samples,2),'sa',x.sa);

surf_ds=cosmo_searchlight(vol_ds,nbrhood,measure);

fprintf('Univariate surface data:\n');
cosmo_disp(surf_ds);

%% Average data in each chunk
% for this example only consider the samples in the first condition
% (targets==1), and average the samples in each chunk
%
% for group analysis: set chunks to (1:nsubj)', assuming each sample is
% data from a single participant
surf_ds=cosmo_slice(surf_ds,surf_ds.sa.targets==1);
surf_ds=cosmo_average_samples(surf_ds);

fn_surf_ds=fullfile(output_path, 'digit_target1.niml.dset');

% save to disc
cosmo_map2surface(surf_ds, fn_surf_ds);
fprintf('Input data saved to %s\n', fn_surf_ds);

%% Run Threshold-Free Cluster Enhancement (TFCE)

% All data is prepared; surf_ds has 8 samples and 5124 nodes. We want to
% see if there are clusters that show a significant difference from zero in
% their response. Thus, .sa.targets is set to all ones (the same
% condition), whereas .sa.chunks is set to (1:8)', indicating that all
% samples are assumed to be independent.
%
% (While this is a within-subject analysis, exactly the same logic can be
% applied to a group-level analysis)

% define neighborhood for each feature
% (cosmo_cluster_neighborhood can be used also for meeg or volumetric
% fmri datasets)
cluster_nbrhood=cosmo_cluster_neighborhood(surf_ds,...
                                        'vertices',vertices,'faces',faces);

fprintf('Cluster neighborhood:\n');
cosmo_disp(cluster_nbrhood);

opt=struct();

% number of null iterations. for publication-quality, use >=1000;
% 10000 is even better
opt.niter=250;

% in this case we run a one-sample test against a mean of 0, and it is
% necessary to specify the mean under the null hypothesis
% (when testing classification accuracies, h0_mean should be set to chance
% level, assuming a balanced crossvalidation scheme was used)
opt.h0_mean=0;

% this example uses the data itself (with resampling) to obtain cluster
% statistcs under the null hypothesis. This is (in this case) somewhat
% conservative due to how the resampling is performed.
% Alternatively, and for better estimates (at the cost of computational
% cost), one can generate a set of (say, 50) datasets using permuted data
% e.g. using cosmo_randomize_targets), put them in a cell and provide
% them as the null argument.
opt.null=[];

fprintf('Running multiple-comparison correction with these options:\n');
cosmo_disp(opt);

% Run TFCE-based cluster correction for multiple comparisons.
% The output has z-scores for each node indicating the probablity to find
% the same, or higher, TFCE value under the null hypothesis
tfce_ds=cosmo_montecarlo_cluster_stat(surf_ds,cluster_nbrhood,opt);

%% Show results

fprintf('TFCE z-score dataset\n');
cosmo_disp(tfce_ds);

nfeatures=size(tfce_ds.samples,2);
percentiles=(1:nfeatures)/nfeatures*100;
plot(percentiles,sort(tfce_ds.samples))
title('sorted TFCE z-scores');
xlabel('feature percentile');
ylabel('z-score');


nvertices=size(vertices,1);
disp_opt=struct();
disp_opt.DataRange=[-2 2];

DispIVSurf(vertices,faces,1:nvertices,tfce_ds.samples',0,disp_opt);

% store results
fn_tfce_ds=fullfile(output_path, 'digit_target1_tfce.niml.dset');
cosmo_map2surface(tfce_ds, fn_tfce_ds);

surf_fn=fullfile(output_path, 'digit_intermediate.asc');
surfing_write(surf_fn,vertices,faces);


% show citation information
cosmo_check_external('-cite');
