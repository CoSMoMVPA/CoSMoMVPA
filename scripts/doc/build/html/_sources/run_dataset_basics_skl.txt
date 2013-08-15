.. run_dataset_basics_skl

run dataset basics skl
======================
.. code-block:: matlab

    %% Dataset basics
    % Set data path, load dataset, set targets and chunks, and add labels as
    % sample attributes
    
    % Set the data path (change cosmo_get_data_path if necessary)
    data_path=cosmo_get_data_path('s01');
    
    % Load dataset (and supply a mask file for 'vt')
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    % Set the targets and the chunks
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    % Add labels as sample attributes
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    %% Overview of the dataset
    ds
    
    %% Overview of sample attributes
    ds.sa
    
    % print targets and chunks
    [ds.sa.targets ds.sa.chunks]
    
    % print labels
    ds.sa.labels
    
    %% Overview of feature attributes
    ds.fa
    
    % print a few voxel indices
    ds.fa.voxel_indices(:,1:10)