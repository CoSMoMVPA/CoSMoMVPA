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
%     >   [ 0.7       0.8       0.9       0.6       0.7       0.6 ]
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
% ACC Aug 2013, modified from run_spherical_neighborhood_searchlight by NNO

    sl_defaults=struct();
    sl_defaults.center_ids=[];
    sl_defaults.progress=1/50;

    sl_opt=cosmo_structjoin(sl_defaults,varargin);
    check_input(ds,nbrhood,measure,sl_opt);

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

    % allocate space for output. res_cell contains the output
    % of the measure applied to each group of features defined in
    % nbrhood. Afterwards the elements in res_cell are combined.
    ncenters=numel(center_ids);
    res_cell=cell(ncenters,1);

    % see if progress is to be reported
    show_progress=~isempty(sl_opt.progress) && sl_opt.progress;
    if show_progress
        progress_step=sl_opt.progress;
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
        catch parent_exception
            % indicate where the error was
            child_exception=MException('',['Searchlight call on feature'...
                                        ' id %d caused an exception'],...
                                            center_id);
            exception=addCause(parent_exception,child_exception);

            rethrow(exception);
        end
        % <@@<

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

    % if it returns sample attribute dimensions, add those
    if cosmo_isfield(res_stacked, 'a.sdim')
        results_map.a.sdim=res_stacked.a.sdim;
    end

    % set center_ids for the output dataset
    results_map.fa.center_ids=center_ids(:)';

    % sanity check of the output
    cosmo_check_dataset(results_map);


function check_input(ds, nbrhood, measure, opt)
    if isa(nbrhood,'function_handle') || ...
                isfield(opt,'args') || ...
                ~isa(measure,'function_handle')
        raise_parameter_exception();
    end


    cosmo_check_dataset(ds);
    cosmo_check_neighborhood(nbrhood);

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
            mfilename())
