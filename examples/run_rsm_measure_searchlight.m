%% Searchlight using a data measure
% 
% Using cosmo_searchlight, run cross-validation with nearest neighbor
% classifier

%% Define data
data_path=cosmo_get_data_path('s01');

ds = cosmo_fmri_dataset([data_path 'glm_betas_allruns.nii'],...
                        'mask',[data_path 'brain_mask.nii']);                                

models_path=cosmo_get_data_path('models');
load([models_path 'v1_model.mat']);
load([models_path 'behav_sim.mat']);                            
                            
%% Set measure 
% Use the rsm measure and set its parameters
% behav similarity in the measure_args struct.
% >>
measure = @cosmo_target_dsm_corr_measure;
measure_args = struct();
measure_args.target_dsm = behav;

results = cosmo_searchlight(ds,measure,'args',measure_args); 

cosmo_map2fmri(results, [data_path 'rsm_measure_searchlight.nii']);

%% Make a histogram of classification accuracies
hist(results.samples,47)


