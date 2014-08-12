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
%               cosmo_spherical_neighborhood (for fMRI datasets).
%       center_ids:      vector indicating center ids to be used as a
%                        searchlight center. By default all feature ids are
%                        used
%       nbrhood:         dataset-like structure but without .sa and
%                         .samples. Required only if radius is
%                         not provided. This forms the template for the
%                         output dataset. It should have the fields:
%         .a              struct with dataset attributes
%         .fa             struct with feature attributes. Each field should
%                         have NF values in the second dimension
%         .neighbors      cell with NF mappings from center_ids in output
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
% See also: cosmo_spherical_neighborhood
%
% ACC Aug 2013, modified from run_spherical_neighborhood_searchlight by NN0

    cosmo_check_dataset(ds);

    defaults=struct();
    defaults.radius=[];
    defaults.center_ids=[];
    defaults.args=struct();
    defaults.nbrhood=[];
    defaults.progress=1/50;
    defaults.parent_type=[]; % for MEEG datasets

    params = cosmo_structjoin(defaults,varargin);
    radius = params.radius;
    args = params.args;
    center_ids=params.center_ids;
    nbrhood=params.nbrhood;

    % use voxel selection function
    if ~xor(isempty(radius), isempty(nbrhood))
        error('need either radius or nbrhood, exclusively');
    elseif isempty(nbrhood)
        if cosmo_check_dataset(ds,'fmri',false)
            nbrhood=cosmo_spherical_neighborhood(ds, radius, params);
        else
            error(['Cannot determine dataset type, and no neighborhood '...
                     'specified in nbrhood']);
        end
    end

    % get the neighborhood information. This is a cell where
    % neighbors{k} contains the feature indices in input dataset 'ds'
    % for the 'k'-th center of the output dataset
    neighbors=nbrhood.neighbors;
    if isempty(center_ids)
        center_ids=1:numel(neighbors); % all output features
    end

    % allocate space for output. res_cell contains the output
    % of the measure applied to each group of features defined in
    % nbrhood. Afterwards the elements in res_cell are combined.
    ncenters=numel(center_ids);
    res_cell=cell(ncenters,1);

    % see if progress is to be reported
    show_progress=~isempty(params.progress) && params.progress;
    if show_progress
        progress_step=params.progress;
        if progress_step<1
            progress_step=ceil(ncenters*progress_step);
        end
        prev_progress_msg='';
        clock_start=clock();
    end

    % Core searchlight code.
    %
    % For each center_id:
    % - get the indices of its neighbors
    % - slice the dataset "ds" using these indices
    % - apply the measure to this sliced dataset with its arguments "args"
    % - store the result in "res"
    %
    % >@@>
    visitorder=randperm(ncenters); % get better progress time estimates

    % if measure gave the wrong result one wants to know sooner rather than
    % later. here only the first result is checked. (other errors may only
    % be caught after this 'for'-loop)
    % this is a compromise between execution speed and error reporting.
    checked_first_output=false;
    
    % little optimization with path checking
    % it assumes that the measure used will not change the path
    on_cleanup_=onCleanup(cosmo_path_changed('not_here'));
    
    for k=1:ncenters
        center_idx=visitorder(k);
        center_id=center_ids(center_idx);
        neighbor_feature_ids=neighbors{center_id};

        % slice the dataset (with disabled kosherness-check)
        sphere_ds=cosmo_slice(ds, neighbor_feature_ids, 2, false);

        % apply the measure
        res=measure(sphere_ds, args);

        % for efficiency, only check first output
        if ~checked_first_output
            if (~isstruct(res) || ~isfield(res,'samples') || ...
                    size(res.samples,2)~=1)
                error(['Measure output must be struct with field .samples '...
                       'that is a column vector']);
            end
            checked_first_output=true;
            args.check_partitions=false;
        end

        res_cell{center_idx}=res;

        % show progress
        if show_progress && (k<10 || ~mod(k,progress_step) || k==ncenters)
            msg='';
            prev_progress_msg=cosmo_show_progress(clock_start, ...
                            k/ncenters, msg, prev_progress_msg);
        end
    end
    % <@@<

    % prepare the output
    results_map=struct();

    % set dataset and feature attributes
    results_map.a=nbrhood.a;

    % slice the feature attributes
    results_map.fa=cosmo_slice(nbrhood.fa,center_ids,2,'struct');

    % join the outputs from the measure for each searchlight position
    res_stacked=cosmo_stack(res_cell,2);
    results_map.samples=res_stacked.samples;

    % if measure returns .sa, add those.
    if isfield(res_stacked,'sa')
        results_map.sa=res_stacked.sa;
    end

    % set center_ids for the output dataset
    results_map.fa.center_ids=center_ids(:)';

    cosmo_check_dataset(results_map);
