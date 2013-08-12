.. cosmo_spherical_voxel_selection_hdr

cosmo spherical voxel selection hdr
===================================
.. code-block:: matlab

    function center2neighbors=cosmo_spherical_voxel_selection(dataset, radius, center_ids)
    % computes neighbors for a spherical searchlight
    %
    % center2neighbors=cosmo_spherical_voxel_selection(dataset, radius[, center_ids])
    %
    % Inputs
    %  - dataset       a dataset struct (from fmri_dataset)
    %  - radius        sphere radius (in voxel units)
    %  - center_ids    Px1 vector with feature ids to consider. If omitted it
    %                  will consider all features in dataset
    % 
    % Output
    %  - center2neighbors  Px1 cell so that center2neighbors{k}==nbrs contains
    %                      the feature ids of the neighbors of feature k
    %                      
    % NNO Aug 2013