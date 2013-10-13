function results_map = cosmo_searchlight(ds, measure, varargin)
%  Generic searchlight function returns a map of results computed at each
%  searchlight location 
%   
%   results_map=cosmo_searchlight(dataset, measure, ['args',args]...
%                           ['radius',radius],['center_ids',center_ids])
%
%   Inputs
%       dataset: an instance of a cosmo_fmri_dataset
%       measure: a function handle to a dataset measure. A dataset measure has
%               the function signature: output = measure(dataset, args)
%       args:   a struct that contains all the fields necessary to the dataset
%               measure. args get passed directly to the dataset measure.
%       radius: searchlight radius in voxels. If provided, the neighborhood
%               function is computed using this radius and the
%               cosmo_spherical_voxel_selection (for fMRI datasets).
%       center_ids:      vector indicating center ids to be used as a 
%                        searchlight center. By default all feature ids are
%                        used
%       ds_fa_a:         dataset-like structure but without .sa and
%                         .samples. Required only if radius is
%                         not provided. This forms the template for the
%                         output dataset. It should have the fields:
%         .a              struct with dataset attributes
%         .fa             struct with feature attributes. Each field should
%                         have NF values in the second dimension
%         .neighborhood   cell with NF mappings from center_ids in output
%                         dataset to feature ids in input dataset. 
%
%   Returns
%       results_map:    a dataset struct where the samples
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
    
    cosmo_check_dataset(ds);

    parser = inputParser;
    addOptional(parser,'radius',[]);
    addOptional(parser,'center_ids',[]);
    addOptional(parser,'args',struct());
    addOptional(parser,'ds_a_fa',[]);
    addOptional(parser,'progress',1/50);
    addOptional(parser,'parent_type',[]); % for MEEG datasets
    
    parse(parser,varargin{:});
    p = parser.Results;
    radius = p.radius;
    args = p.args;
    center_ids=p.center_ids;
    ds_a_fa=p.ds_a_fa;
    parent_type=p.parent_type;

    % use voxel selection function
    if ~xor(isempty(radius), isempty(ds_a_fa))
        error('need either radius or center2neighbors, exclusively');
    elseif isempty(ds_a_fa)
        if cosmo_check_dataset(ds,'fmri',false)
            ds_a_fa=cosmo_spherical_voxel_selection(ds, radius);
        elseif cosmo_check_dataset(ds,'meeg',false)
            ds_a_fa=cosmo_meeg_neighborhood(ds, radius, parent_type);
        else
            error(['Cannot determine dataset type, and no neighborhood '...
                     'specified in ds_a_fa']);
        end
    end
    
    % get the neighborhood information. This is a cell where
    % neighborhood{k} contains the feature indices in input dataset 'ds' 
    % for the 'k'-th center of the output dataset
    neighborhood=ds_a_fa.neighborhood;
    if isempty(center_ids)
        center_ids=1:numel(neighborhood); % all output features
    end
    
    % allocate space for output. res_cell contains the output
    % of the measure applied to each group of features defined in 
    % neighborhood. Afterwards the elements in res_cell are combined.
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
        neighbor_feature_ids=neighborhood{center_id};

        % slice the dataset (with disabled kosherness-check)
        sphere_ds=cosmo_slice(ds, neighbor_feature_ids, 2);

        % apply the measure
        res=measure(sphere_ds, args);
        
        % for efficiency, only check first output
        if k==1 && (~isstruct(res) || ~isfield(res,'samples') || ...
                    size(res.samples,2)~=1)
            error(['Measure output must be struct with field .samples '...
                   'that is a column vector']);
        end
        
        res_cell{k}=measure(sphere_ds, args);
        
        % show progress
        if show_progress && (k<10 || ~mod(k,progress_step) || k==ncenters)
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
    
    % slice the feature attributes
    fa_fns=fieldnames(ds_a_fa.fa);
    for k=1:numel(fa_fns)
        fa_fn=fa_fns{k};
        v=ds_a_fa.fa.(fa_fn);
        
        % select the proper indices
        % for now assume that v is always numeric
        results_map.fa.(fa_fn)=v(:,center_ids);
    end
    
    % join the outputs from the measure for each feature
    res_stacked=cosmo_stack(res_cell,2);
    
    results_map.samples=res_stacked.samples;
    
    % if measure returns .sa, add those.
    if isfield(res_stacked,'sa')
        results_map.sa=res_stacked.sa;
    end
    
    % set center_ids for the output dataset
    results_map.fa.center_ids=center_ids(:)';
    
    cosmo_check_dataset(results_map);
    
    
    