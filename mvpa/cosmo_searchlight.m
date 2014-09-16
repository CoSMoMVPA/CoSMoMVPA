function results_map = cosmo_searchlight(ds, measure, varargin)
%  Generic searchlight function returns a map of results computed at each
%  searchlight location
%
%   results_map=cosmo_searchlight(dataset, measure, ['args',args]...
%                           ['radius',radius],['center_ids',center_ids])
%
% Inputs:
%   ds                   dataset struct with field .samples
%   measure              function handle to a dataset measure. A dataset
%                        measure has the function signature:
%                          output = measure(dataset, args)
%                        where output must be a struct with fields .samples
%                        (as a column vector) and optionally a field .sa
%                        with sample attributes.
%   'args', args         struct that contains all the fields necessary
%                        for the dataset measure. args get passed directly
%                        to the dataset measure
%   'radius', r          searchlight radius in voxels, if ds is an fmri
%                        dataset. Using this option computes the
%                        neighborhood using cosmo_spherical_neighborhood.
%                        This option cannot be used together with
%                        'nbrhood'.
%   'center_ids', ids    vector indicating center ids to be used as a
%                        searchlight center. By default all feature ids are
%                        used (i.e. ids=1:numel(nbrhood.neighbors). The
%                        output results_map.samples has size N in the 2nd
%                        dimension.
%   'nbrhood', nbrhood   dataset-like structure but without .sa and
%                        .samples. This forms the template for the
%                        output dataset. This option cannot be used
%                        together with 'radius'. nbrhood must have fields:
%         .a             struct with dataset attributes
%         .fa            struct with feature attributes. Each field should
%                        have NF values in the second dimension
%         .neighbors     cell with NF mappings from center_ids in output
%                        dataset to feature ids in input dataset.
%
% Output:
%   results_map:         a dataset struct where the samples
%                        contain the results of the searchlight analysis.
%                        If measure returns datasets all of size Nx1 and
%                        there are M center_ids
%                        (M=numel(nbrhood.neighbors)) if center_ids is not
%                        provided), then results_map.samples has size MxN.
%                        If nbrhood has fields .a and .fa, these are part
%                        of the output (with .fa sliced according to
%                        center_ids)
%
% Example:
%     % use a minimal dataset with 6 voxels
%     ds=cosmo_synthetic_dataset('nchunks',5);
%     %
%     % define neighborhood (progress is set to false to suppress output)
%     radius=1; % radius=3 is typical for fMRI datasets
%     nbrhood=cosmo_spherical_neighborhood(ds,radius,'progress',false);
%     %
%     % define measure and its arguments; here crossvalidation with LDA
%     % classifier to compute classification accuracies
%     args=struct();
%     args.classifier = @cosmo_classify_lda;
%     args.partitions = cosmo_nfold_partitioner(ds);
%     measure=@cosmo_crossvalidation_measure;
%     %
%     % run searchlight
%     result=cosmo_searchlight(ds,measure,'args',args,'nbrhood',nbrhood,...
%                                                 'progress',0);
%     %
%     % show results:
%     % - .samples contains classification accuracy
%     % - .fa.nvoxels is the number of voxels in each searchlight
%     % - .fa.radius is the radius of each searchlight
%     cosmo_disp(result)
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'i'  'j'  'k' }
%     >     .values
%     >       { [ 1         2         3 ]  [ 1         2 ]  [ 1 ] }
%     >   .vol
%     >     .mat
%     >       [ 10         0         0         0
%     >          0        10         0         0
%     >          0         0        10         0
%     >          0         0         0         1 ]
%     >     .dim
%     >       [ 3         2         1 ]
%     > .fa
%     >   .nvoxels
%     >     [ 3         4         3         3         4         3 ]
%     >   .radius
%     >     [ 1         1         1         1         1         1 ]
%     >   .center_ids
%     >     [ 1         2         3         4         5         6 ]
%     >   .i
%     >     [ 1         2         3         1         2         3 ]
%     >   .j
%     >     [ 1         1         1         2         2         2 ]
%     >   .k
%     >     [ 1         1         1         1         1         1 ]
%     > .samples
%     >   [ 0.7       0.8       0.9       0.6       0.7       0.6 ]
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
% See also: cosmo_spherical_neighborhood
%
% ACC Aug 2013, modified from run_spherical_neighborhood_searchlight by NNO

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

    visitorder=randperm(ncenters); % get better progress time estimates

    % if measure gave the wrong result one wants to know sooner rather than
    % later. here only the first result is checked. (other errors may only
    % be caught after this 'for'-loop)
    % this is a compromise between execution speed and error reporting.
    checked_first_output=false;


    % Core searchlight code.
    % For each center_id:
    % - get the indices of its neighbors
    % - slice the dataset "ds" using these indices
    % - apply the measure to this sliced dataset with its arguments "args"
    % - store the result in "res"
    %
    for k=1:ncenters
        % >@@>
        center_idx=visitorder(k);
        center_id=center_ids(center_idx);
        neighbor_feature_ids=neighbors{center_id};

        % slice the dataset (with disabled kosherness-check for every
        % but the first neighborhood)
        sphere_ds=cosmo_slice(ds, neighbor_feature_ids, 2, ...
                                        checked_first_output);

        % apply the measure
        % (use try/catch/throw to provide both the feature id
        % that caused the exception, and the original error message)
        try
            res=measure(sphere_ds, args);
        catch mexception
            % indicate where the error was
            msg=sprintf(['Searchlight call on feature id %d caused an '...
                            'exception'],center_id);
            id_exception=MException('CoSMoMVPA:searchlight',msg);
            merged=addCause(id_exception,mexception);
            throw(merged);
        end
        % <@@<

        % for efficiency, only check first output
        if ~checked_first_output
            if ~cosmo_isfield(res, 'samples') || size(res.samples,2)~=1
                error(['Measure output must be struct with field .samples '...
                       'that is a column vector']);
            end
            checked_first_output=true;

            % optimization to switch off checking the partitions
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

    if cosmo_isfield(res_stacked, 'a.sdim')
        results_map.a.sdim=res_stacked.a.sdim;
    end

    % set center_ids for the output dataset
    results_map.fa.center_ids=center_ids(:)';

    cosmo_check_dataset(results_map);
