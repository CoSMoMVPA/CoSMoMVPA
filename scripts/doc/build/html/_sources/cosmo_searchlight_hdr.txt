.. cosmo_searchlight_hdr

cosmo searchlight hdr
=====================
.. code-block:: matlab

    function results_map = cosmo_searchlight(dataset, measure, varargin)
    %  Generic searchlight function returns a map of results computed at each
    %  searchlight location 
    %   
    %   results_map=cosmo_searchlight(dataset, measure, ['args',args]['radius',radius],['center_ids',center_ids])
    %
    %   Inputs
    %       dataset: an instance of a cosmo_fmri_dataset
    %       measure: a function handle to a dataset measure. A dataset measure has
    %               the function signature: output = measure(dataset, args)
    %       args:   a struct that contains all the fields necessary to the dataset
    %               measure. args get passed directly to the dataset measure.
    %       center_ids: vector indicating center ids to be used as a 
    %                        searchlight center. By default all feature ids are
    %                        used
    %       radius: searchlight radius in voxels (default: 3)
    %
    %   Returns
    %       results_map:    an instance of a cosmo_fmri_dataset where the samples
    %                       contain the results of the searchlight analysis.
    % 
    %   Example: Using the searchlight to compute a full-brain nearest neighbor
    %               classification searchlight with n-fold cross validation:
    %
    %       ds = cosmo_fmri_dataset('data.nii.gz','mask','brain_mask.nii.gz', ...
    %                                'targets',targets,'chunks',chunks);
    %       cv = @cosmo_cross_validate;
    %       cv_args = struct();
    %       cv_args.classifier = @cosmo_classify_nn;
    %       cv_args.partitions = cosmo_nfold_partitioner(ds.sa.chunks);
    %       results = cosmo_searchlight(ds,cv,cv_args);     
    %       
    %       
    % ACC Aug 2013, modified from run_voxel_selection_searchlight by NN0