function results_map = cosmo_searchlight(ds, nbrhood, measure, varargin)
%  Generic searchlight function returns a map of results computed at each
%  searchlight location
%
%   results_map=cosmo_searchlight(dataset, nbrhood, measure, ...)
%
% Inputs:
%   ds                   dataset struct with field .samples (NSxNF)
%   nbrhood              Neighborhood structure with fields:
%         .a               struct with dataset attributes
%         .fa              struct with feature attributes. Each field
%                            should have NF values in the second dimension
%         .neighbors       cell with NF mappings from center_ids in output
%                        dataset to feature ids in input dataset.
%                        Suitable neighborhood structs can be generated
%                        using:
%                        - cosmo_spherical_neighborhood (fmri volume)
%                        - cosmo_surficial_neighborhood (fmri surface)
%                        - cosmo_meeg_chan_neigborhood (MEEG channels)
%                        - cosmo_interval_neighborhood (MEEG time, freq)
%                        - cosmo_cross_neighborhood (to cross neighborhoods
%                                                    from the neighborhood
%                                                    functions above)
%   measure              function handle to a dataset measure. A dataset
%                        measure has the function signature:
%                          output = measure(dataset, args)
%                        where output must be a struct with fields .samples
%                        (as a column vector) and optionally a field .sa
%                        with sample attributes.
%                        Typical measures are:
%                        - cosmo_correlation_measure
%                        - cosmo_crossvalidation_measure
%                        - cosmo_target_dsm_corr_measure
%   'center_ids', ids    vector indicating center ids to be used as a
%                        searchlight center. By default all feature ids are
%                        used (i.e. ids=1:numel(nbrhood.neighbors). The
%                        output results_map.samples has size N in the 2nd
%                        dimension.
%   'progress', p        Show progress every p steps
%   'nproc', np          If the Matlab parallel processing toolbox, or the
%                        GNU Octave parallel package is available, use
%                        np parallel threads. (Multiple threads may speed
%                        up searchlight computations).
%                        If parallel processing is not available, or if
%                        this option is not provided, then a single thread
%                        is used.
%   K, V                 any key-value pair (K,V) with arguments for the
%                        measure function handle. Alternatively a struct
%                        can be used
%
% Output:
%   results_map          a dataset struct where the samples
%                        contain the results of the searchlight analysis.
%                        If measure returns datasets all of size Nx1 and
%                        there are M center_ids
%                        (M=numel(nbrhood.neighbors) if center_ids is not
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
%     nbrhood=cosmo_spherical_neighborhood(ds,'radius',radius,...
%                                               'progress',false);
%     %
%     % define measure and its arguments; here crossvalidation with LDA
%     % classifier to compute classification accuracies
%     args=struct();
%     args.classifier = @cosmo_classify_lda;
%     args.partitions = cosmo_nfold_partitioner(ds);
%     measure=@cosmo_crossvalidation_measure;
%     %
%     % run searchlight (without showing progress bar)
%     result=cosmo_searchlight(ds,nbrhood,measure,'progress',0,args);
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
%     >       [ 2         0         0        -3
%     >         0         2         0        -3
%     >         0         0         2        -3
%     >         0         0         0         1 ]
%     >     .dim
%     >       [ 3         2         1 ]
%     >     .xform
%     >       'scanner_anat'
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
%     >   [ 1         1         1       0.9         1       0.7 ]
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
% Notes:
%   - neighborhoods can be defined using one or more of the
%     cosmo_*_neighborhood functions
%
% See also: cosmo_correlation_measure,
%           cosmo_crossvalidation_measure,
%           cosmo_dissimilarity_matrix_measure,
%           cosmo_spherical_neighborhood,cosmo_surficial_neighborhood,
%           cosmo_meeg_chan_neigborhood, cosmo_interval_neighborhood
%           cosmo_cross_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    sl_defaults=struct();
    sl_defaults.center_ids=[];
    sl_defaults.progress=1/50;
    sl_defaults.nproc=1;

    % get options for the searchlight function
    sl_opt=cosmo_structjoin(sl_defaults,varargin);
    check_input(ds,nbrhood,measure,sl_opt);

    % get options for the measure. These are all additional arguments,
    % except that progress is set to false and center_ids is removed.
    measure_opt=rmfield(sl_opt,fieldnames(sl_defaults));
    measure_opt.progress=false;

    center_ids=sl_opt.center_ids;

    % get the neighborhood information. This is a cell where
    % neighbors{k} contains the feature indices in input dataset 'ds'
    % for the 'k'-th center of the output dataset
    neighbors=nbrhood.neighbors;
    if isempty(center_ids)
        center_ids=1:numel(neighbors); % all output features
    end

    % get number of processes for searchlight
    environment=cosmo_wtf('environment');
    nproc_available=get_nproc_available(sl_opt,environment);

    % split neighborhood in multiple parts, so that each thread can do a
    % subset of all the work
    nbrhood_cell=split_nbrhood_for_workers(nbrhood,center_ids,...
                                                    nproc_available);

    % Matlab needs newline character at progress message to show it in
    % parallel mode; Octave should not have newline character
    progress_suffix=get_progress_suffix(environment);

    % set options for each worker process
    worker_opt_cell=cell(1,nproc_available);
    for p=1:nproc_available
        worker_opt=struct();
        worker_opt.ds=ds;
        worker_opt.measure=measure;
        worker_opt.measure_opt=measure_opt;
        worker_opt.worker_id=p;
        worker_opt.nworkers=nproc_available;
        worker_opt.progress=sl_opt.progress;
        worker_opt.progress_suffix=progress_suffix;

        worker_opt.nbrhood=nbrhood_cell{p};
        worker_opt_cell{p}=worker_opt;
    end


    use_parallel=nproc_available>1;
    if use_parallel
        switch environment
            case 'matlab'
                result_cell=cell(1,nproc_available);

                parfor p=1:nproc_available
                    result_cell{p}=run_searchlight_with_worker(...
                                                    worker_opt_cell{p})
                end

            case 'octave'
                result_cell=parcellfun(nproc_available,...
                                        @run_searchlight_with_worker,...
                                        worker_opt_cell,...
                                        'UniformOutput',false,...
                                        'VerboseLevel',0);
        end

        % join results from each worker
        results_map=cosmo_stack(result_cell,2);
    else
        % single thread
        assert(numel(worker_opt_cell)==1)
        results_map=run_searchlight_with_worker(worker_opt_cell{1});
    end

    cosmo_check_dataset(results_map);

function suffix=get_progress_suffix(environment)
    switch environment
        case 'matlab'
            suffix=sprintf('\n');
        case 'octave'
            suffix='';
    end


function results_map=run_searchlight_with_worker(worker_opt)
% run searchlight using the options in worker_opt
    ds=worker_opt.ds;
    nbrhood=worker_opt.nbrhood;
    measure=worker_opt.measure;
    measure_opt=worker_opt.measure_opt;
    worker_id=worker_opt.worker_id;
    nworkers=worker_opt.nworkers;
    progress=worker_opt.progress;
    progress_suffix=worker_opt.progress_suffix;

    neighbors=nbrhood.neighbors;

    % allocate space for output. res_cell contains the output
    % of the measure applied to each group of features defined in
    % nbrhood. Afterwards the elements in res_cell are combined.
    ncenters=numel(nbrhood.neighbors);
    res_cell=cell(ncenters,1);

    % see if progress is to be reported
    show_progress=~isempty(progress) && ...
                        progress && ...
                        worker_id==1;
    if show_progress
        progress_step=progress;
        if progress_step<1
            progress_step=ceil(ncenters*progress_step);
        end
        prev_progress_msg='';
        clock_start=clock();
    end

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
    for center_id=1:ncenters
        % >@@>
        neighbor_feature_ids=neighbors{center_id};

        % slice the dataset (with disabled kosherness-check for every
        % but the first neighborhood)
        sphere_ds=cosmo_slice(ds, neighbor_feature_ids, 2, ...
                                        ~checked_first_output);

        % apply the measure
        % (try/catch can be used to provide an error message indicating
        %  which feature id caused an error)
        try
            res=measure(sphere_ds, measure_opt);

            % for efficiency, only check first output
            if ~checked_first_output
                checked_first_output=true;

                % optimization to switch off checking the partitions,
                % because they don't change for different searchlights
                measure_opt.check_partitions=false;

                cosmo_check_dataset(res);
                if size(res.samples,2)~=1
                    error('Measure output must yield a column vector');
                end
            end
        catch
            caught_error=lasterror();
            caught_error.message=sprintf(['In %s, center id %d caused '...
                                           'an exception:\n%s'],...
                                           mfilename(),...
                                           center_id,...
                                           caught_error.message);
            rethrow(caught_error);
        end
        % <@@<

        res_cell{center_id}=res;

        % show progress
        if show_progress && (center_id<10 || ...
                                ~mod(center_id,progress_step) || ...
                                center_id==ncenters)
            if nworkers>1
                if center_id==ncenters
                    % other workers may be slower than first worker
                    msg=sprintf(['worker %d has completed; waiting for '...
                                    'other workers to finish...%s'],...
                                    worker_id, progress_suffix);
                else
                    % can only show progress from a single worker;
                    % therefore show progress of first worker
                    msg=sprintf('for worker %d / %d%s', worker_id, ...
                                    nworkers, progress_suffix);
                end
            else
                % no specific message
                msg='';
            end
            prev_progress_msg=cosmo_show_progress(clock_start, ...
                            center_id/ncenters, msg, prev_progress_msg);
        end
    end

    % prepare the output
    results_map=struct();

    % set dataset and feature attributes
    results_map.a=nbrhood.a;

    % slice the feature attributes
    results_map.fa=nbrhood.fa;

    % join the outputs from the measure for each searchlight position
    res_stacked=cosmo_stack(res_cell,2);
    results_map.samples=res_stacked.samples;

    % if measure returns .sa, add those.
    if isfield(res_stacked,'sa')
        results_map.sa=res_stacked.sa;
    end

    % if it returns sample attribute dimensions, add those
    if cosmo_isfield(res_stacked, 'a.sdim')
        results_map.a.sdim=res_stacked.a.sdim;
    end


function nbrhood_cell=split_nbrhood_for_workers(nbrhood,center_ids,nproc)
% splits the neighborhood in multiple smaller neighborhoods that can be
% used in parallel
    ncenters=numel(center_ids);

    block_size=ceil(ncenters/nproc);
    nbrhood_cell=cell(nproc,1);

    first=1;
    for block=1:nproc
        last=min(first+block_size-1,ncenters);
        block_idxs=first:last;

        block_center_ids=center_ids(block_idxs);

        block_nbrhood=struct();
        block_nbrhood.neighbors=nbrhood.neighbors(block_center_ids);
        block_nbrhood.a=nbrhood.a;
        block_nbrhood.fa=cosmo_slice(nbrhood.fa,block_center_ids,2,...
                                                            'struct');
        block_nbrhood.fa.center_ids=block_center_ids(:)';

        nbrhood_cell{block}=block_nbrhood;

        first=last+1;
    end


function check_input(ds, nbrhood, measure, opt)
    if isa(nbrhood,'function_handle') || ...
                isfield(opt,'args') || ...
                ~isa(measure,'function_handle')
        raise_parameter_exception();
    end

    nproc=opt.nproc;
    if ~(isnumeric(nproc) && ...
            isscalar(nproc) && ...
            round(nproc)==nproc && ...
            nproc>=1)
        error('nproc must be positive scalar');
    end

    cosmo_check_dataset(ds);
    cosmo_check_neighborhood(nbrhood,ds);


function nproc=get_nproc_available(sl_opt, environment)
% get number of processes available from Matlab parallel processing pool.
% return nproc=1 if no parallel processing pool available
    nproc_wanted=sl_opt.nproc;

    wants_multithreaded = nproc_wanted>1;
    if wants_multithreaded
        switch environment
            case 'matlab'
                nproc_available=get_nproc_available_matlab(nproc_wanted);

            case 'octave'
                nproc_available=get_nproc_available_octave(nproc_wanted);

            otherwise
                assert(false);

        end

        nproc=nproc_available;

        if nproc_available==1
            cosmo_warning(['Parallel computing not available, using '...
                            'single thread']);
            nproc=1;
        end
    else
        nproc=1;
    end

function nproc_available=get_nproc_available_matlab(nproc_wanted)
    matlab_parallel_functions={'gcp','parpool'};

    if usejava('jvm') && platform_has_functions(matlab_parallel_functions)
        pool = gcp();

        if isempty(pool)
            cosmo_warning(['Parallel toolbox is available, but '...
                            'unable to open pool; using nproc=1']);
            nproc_available=1;
        else
            nworkers=pool.NumWorkers();

            if nproc_wanted>nworkers
                cosmo_warning(['nproc=%d requested but only %d '...
                            'workers available; recommended '...
                            'usage is nproc=%d'],...
                            nproc_wanted,nworkers,nworkers);
            end

            nproc_available=nproc_wanted;
        end
    else
        nproc_available=1;
        if nproc_wanted>nproc_available
            cosmo_warning(['nproc=%d requested but parallel toolbox '...
                            'or java not available; using nproc=%d'], ...
                            nproc_wanted, nproc_available);
        end
    end

function nproc_available=get_nproc_available_octave(nproc_wanted)
% return nproc_wanted if the Octave 'parallel' package is available, or 1
% otherwise
% (the parallel package does not support returning the number
% of CPUs available)
    if cosmo_check_external('octave_pkg_parallel',false)
        nworkers=nproc('all');

        if nproc_wanted>nworkers
                cosmo_warning(['nproc=%d requested but only %d '...
                            'workers available; recommended '...
                            'usage is nproc=%d'],...
                            nproc_wanted,nworkers);
        end

        nproc_available=nproc_wanted;
    else
        nproc_available=1;
        if nproc_wanted>nproc_available
            cosmo_warning(['nproc=%d requested but parallel toolbox '...
                            'not available; setting nproc=%d'], ...
                            nproc_wanted, nproc_available);
        end
    end


function tf=platform_has_functions(function_names)
    tf=all(cellfun(@(x)~isempty(which(x)),function_names));

function raise_parameter_exception()
    error(['Illegal syntax, use:\n\n',...
            '  %s(ds,nbrhood,measure,...)\n\n',...
            'where \n',...
            '- ds is a dataset struct\n',...
            '- nbrhood is a neighborhood struct\n',...
            '- measure is a function handle of a dataset measure\n',...
            '- any arguments to measure can be given at the ''...''\n',...
            '  position, or as a struct\n',...
            '(Note: as of January 2015 the syntax for this function\n'...
            'has changed. The neighboorhood argument is now a fixed\n'...
            'parameter, and measure arguments are passed directly\n'...
            'rather than through an ''args'' arguments'], ...
            mfilename());
