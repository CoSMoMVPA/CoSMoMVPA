.. run_operations_on_datasets_skl

run operations on datasets skl
==============================
.. code-block:: matlab

    %% Dataset Basics
    % Run operations on datasets
    %
    
    %% Load data and set targets
    % Load data as before setting targets and chunks appropriately
    
    data_path=cosmo_get_data_path('s01');
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    %% Set the sample indices that correspond to primates and bugs
    
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    %% Slice the dataset
    % use the indices as input to the dataset samples slicer
    
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    %% Subtract mean pattern
    % Find the mean pattern for primates and bugs and subtract the bug pattern from
    % the primate pattern
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    %% Store and visualize the results
    % Finally save the result as a dataset with the original header
    % Just replace ds.samples with the result. Convert back to nifti and save it
    % using cosmo_map2nifti function.
    
    %%%% >>> YOUR CODE HERE <<< %%%%
    