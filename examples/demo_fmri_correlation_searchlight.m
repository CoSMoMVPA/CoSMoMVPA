%% Demo: fMRI searchlights with split-half correlations, classifier, and representational similarity analysis
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

% reset citation list
cosmo_check_external('-tic');

% set result directory
output_path=config.output_data_path;


%% Example: split-half correlation measure (Haxby 2001-style)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This example uses the 'ak6' dataset

% define data filenames & load data from even and odd runs

data_path=fullfile(ak6_study_path,'s01'); % data from subject s01
mask_fn=fullfile(data_path, 'brain_mask.nii'); % whole brain mask

data_odd_fn=fullfile(data_path,'glm_T_stats_odd.nii');
ds_odd=cosmo_fmri_dataset(data_odd_fn,'mask',mask_fn,...
                            'targets',1:6,'chunks',1);


data_even_fn=fullfile(data_path,'glm_T_stats_even.nii');
ds_even=cosmo_fmri_dataset(data_even_fn,'mask',mask_fn,...
                            'targets',1:6,'chunks',2);

% Combine even and odd runs
ds_odd_even=cosmo_stack({ds_odd, ds_even});

% print dataset
fprintf('Dataset input:\n');
cosmo_disp(ds_odd_even);

% Use cosmo_correlation_measure.
% This measure returns, by default, a split-half correlation measure
% based on the difference of mean correlations for matching and
% non-matching conditions (a la Haxby 2001).
measure=@cosmo_correlation_measure;

% define spherical neighborhood with radius of 3 voxels
radius=3; % voxels
nbrhood=cosmo_spherical_neighborhood(ds_odd_even,'radius',3);

% Run the searchlight with a 3 voxel radius
corr_results=cosmo_searchlight(ds_odd_even,nbrhood,measure);

% print output
fprintf('Dataset output:\n');
cosmo_disp(corr_results);


% Plot the output
cosmo_plot_slices(corr_results);

% Define output location
output_fn=fullfile(output_path,'corr_searchlight.nii');

% Store results to disc
cosmo_map2fmri(corr_results, output_fn);

% Show citation information
cosmo_check_external('-cite');
