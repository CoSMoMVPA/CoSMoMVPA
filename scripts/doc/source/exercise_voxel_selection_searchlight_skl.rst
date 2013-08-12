.. exercise_voxel_selection_searchlight_skl

exercise voxel selection searchlight skl
========================================
.. code-block:: matlab

    datadir='../data/small/s01/stats/';
    fn=[datadir 'glm_T_stats_perrun.nii.gz'];
    maskfn=[datadir 'brain_mask.nii.gz'];
    radius=3;
    targets=repmat(1:6,1,10);
    chunks=floor(((1:60)-1)/6)+1;
    classifier=@cosmo_classify_nn;
    
    % load data and set sample attributes
    ds=cosmo_fmri_dataset(fn, 'mask', maskfn, 'targets', targets, 'chunks', chunks);
    nfeatures=size(ds.samples,2);
    center_ids=1:nfeatures; % for now, consider all voxels
    
    % use voxel selection function
    center2neighbors=cosmo_spherical_voxel_selection(ds, radius, center_ids);
    %%
    % for cross validation
    partitions=cosmo_nfold_partition(ds.sa.chunks);
    
    % space for output
    ncenters=numel(center_ids);
    accs=zeros(1,ncenters);
    
    % go over all features, run cross-validation and store the classiifcation
    % accuracies.
    % [your code here]
    
    % store the output
    res_map=ds;
    res_map.samples=accs;
    
    map2nifti(res_map,[datadir  '_slmap7.nii.gz']);