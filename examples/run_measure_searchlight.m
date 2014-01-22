%% Searchlight using a data measure
% 
% Using cosmo_searchlight, run cross-validation with nearest neighbor
% classifier

%% Define data
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

targets=repmat(1:6,1,10);
chunks=floor(((1:60)-1)/6)+1;

ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii'],...
                        'mask',[data_path '/brain_mask.nii'], ...
                                'targets',targets,'chunks',chunks);

%% Set measure 
% Use the cosmo_cross_validation_measure and set its parameters
% (classifier and partitions) in a measure_args struct.
% >@@>
measure = @cosmo_cross_validation_accuracy_measure;
measure_args = struct();
measure_args.classifier = @cosmo_classify_nn; 
measure_args.partitions = cosmo_oddeven_partitioner(ds); 

% <@@<

%% Run the searchlight
results = cosmo_searchlight(ds,measure,'args',measure_args,'radius',3); 

% the following command would store the results to disk:
% >> cosmo_map2fmri(results, [data_path 'measure_searchlight.nii']);

%% Make a histogram of classification accuracies
hist(results.samples,47)

%% Plot a map
cosmo_plot_slices(results);