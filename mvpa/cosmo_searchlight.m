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
%       radius: searchlight radius in voxels. If provided, the mapping from
%               center2neighbors is computed using this radius and the
%               cosmo_spherical_voxel_selection function
%       center_ids:      vector indicating center ids to be used as a 
%                        searchlight center. By default all feature ids are
%                        used
%       center2neighbors: Px1 cell, if the dataset has P features, so that 
%                         center2neighbors{K} contains the features that 
%                         are in the neighborhood of the k-th feature.
%                         This option is mutually exclusive with radius.
%       ds_a_fa           dataset-like structure but without .sa and
%                         .samples. Required only if center2neighbors is
%                         not provided. This forms the template for the
%                         output dataset. It should have the fields:
%         .a              struct with dataset attributes
%         .fa             struct with feature attributes
%       
%
%   Returns
%       results_map:    an instance of a cosmo_fmri_dataset where the samples
%                       contain the results of the searchlight analysis.
% 
%   Example: Using the searchlight to compute a full-brain nearest neighbor
%               classification searchlight with n-fold cross validation:
%
%       ds = cosmo_fmri_dataset('data.nii','mask','brain_mask.nii', ...
%                                'targets',targets,'chunks',chunks);
%       m = @cosmo_cross_validation_accuracy_measure;
%       m_args = struct();
%       m_args.classifier = @cosmo_classify_nn;
%       m_args.partitions = cosmo_nfold_partitioner(ds);
%       results = cosmo_searchlight(ds,m,'args',m_args,'radius',3);
% See also: cosmo_spherical_voxel_selection       
%
% ACC Aug 2013, modified from run_voxel_selection_searchlight by NN0
    
    cosmo_check_dataset(dataset);
    nfeatures=size(dataset.samples,2);

    parser = inputParser;
    addOptional(parser,'radius',[]);
    addOptional(parser,'center_ids',1:nfeatures);
    addOptional(parser,'args',struct());
    addOptional(parser,'center2neighbors',[]);
    addOptional(parser,'ds_a_fa',[]);
    addOptional(parser,'progress',1/50);
    parse(parser,varargin{:});
    p = parser.Results;
    radius = p.radius;
    args = p.args;
    center_ids=p.center_ids;
    center2neighbors=p.center2neighbors;
    ds_a_fa=p.ds_a_fa;

    % use voxel selection function
    if ~xor(isempty(radius), isempty(center2neighbors))
        error('need either radius or center2neighbors, exclusively');
    elseif isempty(center2neighbors)
        if ~isempty(ds_a_fa)
            error('center2neighbors not specified but ds_a_fa is?');
        end
        [center2neighbors,ds_a_fa]=cosmo_spherical_voxel_selection(dataset, radius, center_ids);
    else
        if isempty(ds_a_fa)
            error('center2neighbors specified but ds_a_fa is not?');
        end
        center2neighbors={center2neighbors{center_ids}};
        ds_a_fa=cosmo_slice(ds, center_ids);
    end

    % space for output, we will leave res empty for now because we can't know
    % yet the size of the array returned by our dtaset measure. Instead 
    % space will be allocated after the first times the measure is used. 
    ncenters=numel(center_ids);
    res_cell=cell(ncenters,1);
    % see if progress is to be reported
    show_progress=~isempty(p.progress);
    if show_progress
        progress_step=p.progress;
        if progress_step<1
            progress_step=ceil(ncenters*progress_step);
        end
        prev_progress_msg='';
        clock_start=clock();
    end
    
    % go over all features; for each feature, apply the measure and 
    % store its output.
    % >>
    for k=1:ncenters
        center_id=center_ids(k);
        sphere_feature_ids=center2neighbors{center_id};

        % slice the dataset (with disabled kosherness-check)
        sphere_ds=cosmo_slice(dataset, sphere_feature_ids, 2);

        % apply the measure
        res_cell{k}=measure(sphere_ds, args);
        
        % show progress
        if show_progress && (k==1 || mod(k,progress_step)==0 || k==nfeatures)
            msg='';
            prev_progress_msg=cosmo_show_progress(clock_start, ...
                            k/ncenters, msg, prev_progress_msg);
        end
    end
    % <<
    
    % prepare the output
    results_map=struct();
    
    % set dataset and feature attributes
    results_map.a=ds_a_fa.a;
    results_map.fa=ds_a_fa.fa;
    
    % join the outputs from the measure for each feature
    res_stacked=cosmo_stack(res_cell,2);
    
    results_map.samples=res_stacked.samples;
    results_map.sa=res_stacked.sa;
    
    % set center_ids for the output dataset
    all_feature_ids=1:size(dataset.samples,2);
    results_map.fa.center_ids=reshape(all_feature_ids(center_ids),1,[]);
    
    return
    
    % <<

    % store the output in a dataset
    results_map=ds_a_fa;
    
    % make sure it has no sample attributes
    if isfield(results_map, 'sa')
        results_map=rmfield(results_map,'sa');
    end
    
    % store the result from the measure
    results_map.samples=res;
    
    