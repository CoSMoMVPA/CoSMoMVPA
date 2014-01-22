%% Searchlight using a data measure
% 
% Using cosmo_searchlight, run cross-validation with nearest neighbor
% classifier

%% Define data
config=cosmo_config();
study_path=fullfile(config.tutorial_data_path,'ak6');

data_path=fullfile(study_path,'s01');
data_fn=fullfile(data_path,'glm_T_stats_perrun.nii');
mask_fn=fullfile(data_path,'brain_mask.nii');
targets=repmat(1:6,1,10)';
ds = cosmo_fmri_dataset(data_fn, ...
                        'mask',mask_fn,...
                        'targets',targets);                        
                    
% compute average for each unique target, so that the dataset has 6
% samples - one for each target
ds=cosmo_fx(ds, @(x)mean(x,1), 'targets', 1);

models_path=fullfile(study_path,'models');
load(fullfile(models_path,'v1_model.mat'));
load(fullfile(models_path,'behav_sim.mat'));                            
                            
%% Set measure 
% Use the rsm measure and set its parameters
% behav similarity in the measure_args struct.
% >@@>
measure = @cosmo_target_dsm_corr_measure;
measure_args = struct();
measure_args.target_dsm = behav;
% <@@<

% Run the searchlight
results = cosmo_searchlight(ds,measure,'args',measure_args,'radius',3); 

% Save the results to disc using the following command:
% >> cosmo_map2fmri(results, [data_path 'rsm_measure_searchlight.nii']);

%% Make a histogram of classification accuracies
hist(results.samples,47)

%% Show some slices
cosmo_plot_slices(results);
