.. run_measure_searchlight_skl

run measure searchlight skl
===========================
.. code-block:: matlab

    %% Searchlight using a data measure
    % 
    % Using cosmo_searchlight, run cross-validation with nearest neighbor
    % classifier
    
    %% Define data
    data_path=cosmo_get_data_path('s01');
    targets=repmat(1:6,1,10);
    chunks=floor(((1:60)-1)/6)+1;
    
    ds = cosmo_fmri_dataset([data_path 'glm_T_stats_perrun.nii'],...
                            'mask',[data_path 'brain_mask.nii'], ...
                                    'targets',targets,'chunks',chunks);
                                
    %% Set measure 
    % Use the cosmo_cross_validation_measure and set its parameters
    % (classifier and partitions) in a measure_args struct.
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    %% Run the searchlight
    results = cosmo_searchlight(ds,measure,'args',measure_args); 
    
    cosmo_map2nifti(results, [data_path 'measure_searchlight.nii']);
    
    %% Make a histogram of classification accuracies
    hist(results.samples,47)