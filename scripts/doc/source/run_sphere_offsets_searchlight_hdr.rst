.. run_sphere_offsets_searchlight_hdr

run sphere offsets searchlight hdr
==================================
.. code-block:: matlab

    %% Searchlight analysis in the volume
    %
    % This analysis is quite bare-bones - data is loaded directly through
    % load_nii rather than through fmri_dataset, and voxel indices in each
    % searchlight are computed directly in this script rather than using
    % a helper function such as sphereical_voxel_selection.
    %
    % NNO Aug 2013