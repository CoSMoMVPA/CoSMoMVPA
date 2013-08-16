.. run_load_datasets_hdr

run load datasets hdr
=====================
.. code-block:: matlab

    %% Dataset Basics
    % Load datasets using cosmo_fmri_dataset
    %
    % This function loads data stored in a nifti file and return a dataset struct
    % where the data are store in the 2-D array in field dataset.samples
    %
    % For each of the three masks ('brain','ev','vt'), 
    % print the number of voxels when loading the dataset with that mask.
    %
    % Hint: the number of voxels is given by the number of columns in
    % dataset.samples