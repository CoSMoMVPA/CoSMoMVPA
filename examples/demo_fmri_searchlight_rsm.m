%% Demo: fMRI searchlights with representational similarity analysis
%
% The data used here is available from http://cosmomvpa.org/datadb.zip
%
% This example uses the following dataset:
% - 'ak6' is based on the following work (please cite if you use it):
%    Connolly et al (2012), Representation of biological classes in the
%    human brain. Journal of Neuroscience,
%    doi 10.1523/JNEUROSCI.5547-11.2012
%
%    Six categories (monkey, lemur, mallard, warbler, ladybug, lunamoth)
%    during ten runs in an fMRI study. Using the General Linear Model
%    response were estimated for each category in each run, resulting
%    in 6*10=60 t-values.
%
% The example shows a searchlight analysis matching local neural similarity
% patterns to three different target similarity matrices
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


%% Set data paths
% The function cosmo_config() returns a struct containing paths to tutorial
% data. (Alternatively the paths can be set manually without using
% cosmo_config.)
config=cosmo_config();

ak6_study_path=fullfile(config.tutorial_data_path,'ak6');

% show readme information
readme_fn=fullfile(ak6_study_path,'README');
cosmo_type(readme_fn);

output_path=config.output_data_path;

% reset citation list
cosmo_check_external('-tic');


%% Load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This example uses the 'ak6' dataset
% In this example only one sample (response estimate) per condition (class)
% per feature (voxel) is used. Here this is done using t-stats from odd
% runs. One could also use output from a GLM based on an entire
% scanning session experiment.
%

% define data filenames & load data from even and odd runs

data_path=fullfile(ak6_study_path,'s01'); % data from subject s01
mask_fn=fullfile(data_path, 'brain_mask.nii'); % whole brain mask

data_fn=fullfile(data_path,'glm_T_stats_odd.nii');
ds=cosmo_fmri_dataset(data_fn,'mask',mask_fn,...
                            'targets',1:6,'chunks',1);

%% Set animal species & class
ds.sa.labels={'monkey','lemur','mallard','warbler','ladybug','lunamoth'}';
ds.sa.animal_class=[1 1 2 2 3 3]';

% simple sanity check to ensure all attributes are set properly
cosmo_check_dataset(ds);

% print dataset
fprintf('Dataset input:\n');
cosmo_disp(ds);

%% Define feature neighorhoods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For the searchlight, define neighborhood for each feature (voxel).
nvoxels_per_searchlight=100;

% The neighborhood defined here is used three times (one for each target
% similarity matrix), so it is not recomputed for every searchlight call.
fprintf('Defining neighborhood for each feature\n');
nbrhood=cosmo_spherical_neighborhood(ds,'count',nvoxels_per_searchlight);

% print neighborhood
fprintf('Searchlight neighborhood definition:\n');
cosmo_disp(nbrhood);


%% Simple RSM searchlight
nsamples=size(ds.samples,1);
target_dsm=zeros(nsamples);

% define 'simple' target structure where primates (monkey, lemur),
% birds (mallard, warbler) and insects (ladybug, lunamoth) are the same
% (distance=0), all other pairs are equally dissimilar (distance=1).
% Given the ds.sa.targets assignment, pairs (1,2), (3,4) and (5,6) have
% distance 0, all others distance 1.
animal_class=ds.sa.animal_class;
for row=1:nsamples
    for col=1:nsamples
        same_animal_class=animal_class(row)==animal_class(col);

        if same_animal_class
            target_dsm(row,col)=0;
        else
            target_dsm(row,col)=1;
        end
    end
end

fprintf('Using the following target dsm\n');
disp(target_dsm);
imagesc(target_dsm)
set(gca,'XTick',1:nsamples,'XTickLabel',ds.sa.labels,...
        'YTick',1:nsamples,'YTickLabel',ds.sa.labels)

% set measure
measure=@cosmo_target_dsm_corr_measure;
measure_args=struct();
measure_args.target_dsm=target_dsm;

% print measure and arguments
fprintf('Searchlight measure:\n');
cosmo_disp(measure);
fprintf('Searchlight measure arguments:\n');
cosmo_disp(measure_args);

% run searchlight
ds_rsm_binary=cosmo_searchlight(ds,nbrhood,measure,measure_args);

% Note: when these results are used for group analysis across multiple
% participants, it may be good to Fisher-transform the correlation values,
% so that they are more normally distributed. This can be done by:
%
% ds_rsm_binary.samples=atanh(ds_rsm_binary.samples);


% show results
cosmo_plot_slices(ds_rsm_binary);

% store results
output_fn=fullfile(output_path,'rsm_binary.nii');
cosmo_map2fmri(ds_rsm_binary,output_fn);


%% Using another RSM

% This example is very similar to the previous example.
% - This example uses a different target representational similarity
%   matrix. The code below allows for identifying regions that show a
%   linear dissimilarity across animal class, with primates of distance 1
%   from birdsand distance 2 from insects, and insects distance 1 from
%   birds. Graphically:
%
%            +------------------+------------------+
%        primates             birds             insects
%     {monkey,lemur}     {mallard,warbler}   {ladybug,lunamoth}
%
% - It uses a Spearman rather than Pearson correlation measure to match
%   the neural similarity to the target similarity measure

animal_class=ds.sa.animal_class;

% compute absolute difference between each pair of samples
target_dsm=abs(bsxfun(@minus,animal_class,animal_class'));

fprintf('Using the following target dsm\n');
disp(target_dsm);
imagesc(target_dsm)
set(gca,'XTick',1:nsamples,'XTickLabel',ds.sa.labels,...
        'YTick',1:nsamples,'YTickLabel',ds.sa.labels)

% set measure
measure=@cosmo_target_dsm_corr_measure;
measure_args=struct();
measure_args.target_dsm=target_dsm;

% 'Spearman' requires  matlab with stats toolbox; if not present use
% 'Pearson'
if cosmo_check_external('@stats',false)
    measure_args.type='Spearman';
else
    measure_args.type='Pearson';
    fprintf('Matlab stats toolbox not present, using %s correlation\n',...
                measure_args.type)
end

% run searchlight
ds_rsm_linear=cosmo_searchlight(ds,nbrhood,measure,measure_args);

% Note: when these results are used for group analysis across multiple
% participants, it may be good to Fisher-transform the correlation values,
% so that they are more normally distributed. This can be done by:
%
% ds_rsm_linear.samples=atanh(ds_rsm_linear.samples);

% show results
cosmo_plot_slices(ds_rsm_linear);

% store results
output_fn=fullfile(output_path,'rsm_linear.nii');
cosmo_map2fmri(ds_rsm_linear,output_fn);


%% Using a behavioural RSM
% This example is very similar to the one above, but now the target
% similarity structure is based on behavioural similarity ratings

% load behavioural similarity matrix from disc
behav_model_fn=fullfile(ak6_study_path,'models','behav_sim.mat');
behav_model=importdata(behav_model_fn);

target_dsm=behav_model;

fprintf('Using the following target dsm\n');
disp(target_dsm);
imagesc(target_dsm)
set(gca,'XTick',1:nsamples,'XTickLabel',ds.sa.labels,...
        'YTick',1:nsamples,'YTickLabel',ds.sa.labels)

% set measure
measure=@cosmo_target_dsm_corr_measure;
measure_args=struct();
measure_args.target_dsm=target_dsm;

% run searchlight
ds_rsm_behav=cosmo_searchlight(ds,nbrhood,measure,measure_args);

% Note: when these results are used for group analysis across multiple
% participants, it may be good to Fisher-transform the correlation values,
% so that they are more normally distributed. This can be done by:
%
% ds_rsm_behav.samples=atanh(ds_rsm_behav.samples);

% show results
cosmo_plot_slices(ds_rsm_behav);

% store results
output_fn=fullfile(output_path,'rsm_behav.nii');
cosmo_map2fmri(ds_rsm_behav,output_fn);

% Show citation information
cosmo_check_external('-cite');
