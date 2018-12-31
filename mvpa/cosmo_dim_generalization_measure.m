function result=cosmo_dim_generalization_measure(ds,varargin)
% measure generalization across pairwise combinations over time (or any other dimension)
%
% result=cosmo_dim_generalization_measure(ds,varargin)
%
% Inputs:
%   ds                  dataset struct with d being a sample dimension, and
%                       with ds.sa.chunks==1 for samples to use for
%                       training and ds.sa.chunks==2 for those to use for
%                       testing. Other values for chunks are not allowed.
%   'measure',m         function handle to apply to combinations of samples
%                       in the input dataset ds, such as
%                       - @cosmo_correlation_measure
%                       - @cosmo_crossvalidation_measure
%                       - @cosmo_target_dsm_corr_measure
%   'dimension',d       dimension along which to generalize. Typically this
%                       will be 'time' for MEEG data
%   'radius',r          radius used for the d dimension. For example, when
%                       set to r=4 with d='time', then 4*2+1 time points
%                       are used to asses generalization, (except on the
%                       edges). Note that when using a radius>0, it is
%                       assumed that splits of the dataset by dimension d
%                       have corresponding elements in the same order
%                       (such as provided by cosmo_dim_transpose).
%   'nproc', np         Use np parallel threads. (Multiple threads may
%                       speed up computations). If parallel processing is 
%                       not available, or if this option is not provided, 
%                       then a single thread is used.
%   K,V                 any other key-value pairs necessary for the measure
%                       m, for example 'classifier' if
%                       m=@cosmo_crossvalidation_measure.
%
% Output:
%    result             dataset with ['train_' d] and ['test_' d] as sample
%                       dimensions, i.e. these are in ds.a.sdim.labels
%                       result.samples is Nx1, where N=K*J is the number of
%                       combinations of (1) the K points in ds with
%                       chunks==1 and different values in dimension d, and
%                       (2) the J points in ds with chunks==2 and different
%                       values in dimension d.
%
% Examples:
%     % Generalization over time
%     sz='big';
%     train_ds=cosmo_synthetic_dataset('type','timelock','size',sz,...
%                                              'nchunks',2,'seed',1);
%     test_ds=cosmo_synthetic_dataset('type','timelock','size',sz,...
%                                              'nchunks',3,'seed',2);
%     % set chunks
%     train_ds.sa.chunks(:)=1;
%     test_ds.sa.chunks(:)=2;
%     %
%     % construct the dataset
%     ds=cosmo_stack({train_ds, test_ds});
%     %
%     % make time a sample dimension
%     dim_label='time';
%     ds_time=cosmo_dim_transpose(ds,dim_label,1);
%     %
%     % set measure and its arguments
%     measure_args=struct();
%     %
%     % use correlation measure
%     measure_args.measure=@cosmo_correlation_measure;
%     % dimension of interest is 'time'
%     measure_args.dimension=dim_label;
%     %
%     % run time-by-time generalization analysis
%     dgm_ds=cosmo_dim_generalization_measure(ds_time,measure_args,...
%                                               'progress',false);
%     %
%     % the output has train_time and test_time as sample dimensions
%     cosmo_disp(dgm_ds.a)
%     %|| .sdim
%     %||   .labels
%     %||     { 'train_time'  'test_time' }
%     %||   .values
%     %||     { [  -0.2        [  -0.2
%     %||         -0.15          -0.15
%     %||          -0.1           -0.1
%     %||           :              :
%     %||             0              0
%     %||          0.05           0.05
%     %||           0.1 ]@7x1      0.1 ]@7x1 }
%
%
%     % Searchlight example
%     % (This example requires FieldTrip)
%     cosmo_skip_test_if_no_external('fieldtrip');
%     %
%     sz='big';
%     train_ds=cosmo_synthetic_dataset('type','timelock','size',sz,...
%                                              'nchunks',2,'seed',1);
%     test_ds=cosmo_synthetic_dataset('type','timelock','size',sz,...
%                                              'nchunks',3,'seed',2);
%     % set chunks
%     train_ds.sa.chunks(:)=1;
%     test_ds.sa.chunks(:)=2;
%     %
%     % construct the dataset
%     ds=cosmo_stack({train_ds, test_ds});
%     %
%     % make time a sample dimension
%     dim_label='time';
%     ds_time=cosmo_dim_transpose(ds,dim_label,1);
%     %
%     % set measure and its arguments
%     measure_args=struct();
%     %
%     % use correlation measure
%     measure_args.measure=@cosmo_correlation_measure;
%     % dimension of interest is 'time'
%     measure_args.dimension=dim_label;
%     %
%     % only to make this example run fast, most channels are eliminated
%     % (there is no other reason to do this step)
%     ds_time=cosmo_slice(ds_time,ds_time.fa.chan<=20,2);
%     ds_time=cosmo_dim_prune(ds_time);
%     %
%     % define neighborhood for channels
%     nbrhood=cosmo_meeg_chan_neighborhood(ds_time,...
%                                 'chantype','meg_combined_from_planar',...
%                                 'count',5,'label','dataset');
%     %
%     % run searchlight with generalization measure
%     measure=@cosmo_dim_generalization_measure;
%     dgm_sl_ds=cosmo_searchlight(ds_time,nbrhood,measure,measure_args,...
%                                                 'progress',false);
%     %
%     % the output has train_time and test_time as sample dimensions,
%     % and chan as feature dimension
%     cosmo_disp(dgm_sl_ds.a,'edgeitems',1)
%     %|| .fdim
%     %||   .labels
%     %||     { 'chan' }
%     %||   .values
%     %||     { { 'MEG0112+0113' ... 'MEG0712+0713'   }@1x7 }
%     %|| .meeg
%     %||   .samples_type
%     %||     'timelock'
%     %||   .samples_field
%     %||     'trial'
%     %||   .samples_label
%     %||     'rpt'
%     %|| .sdim
%     %||   .labels
%     %||     { 'train_time'  'test_time' }
%     %||   .values
%     %||     { [ -0.2        [ -0.2
%     %||           :             :
%     %||          0.1 ]@7x1     0.1 ]@7x1 }
%
%
% Notes:
%   - this function can be used together with searchlight
%   - to make a dimension d a sample dimension from a feature dimension
%     (usually necessary before running this function), or the other way
%     around (usually necessary after running this function), use
%     cosmo_dim_transpose.
%   - a 'partition' argument should not be provided, because this function
%     generates them itself. The partitions are generated so that there
%     is a single fold; samples with chunks==1 are always used for training
%     and those with chunks==2 are used for testing (e.g. when using
%     m=@cosmo_crossvalidation_measure). In the case of using
%     m=@cosmo_correlation_measure, this amounts to split-half
%     correlations.
%
% See also: cosmo_correlation_measure, cosmo_crossvalidation_measure
%           cosmo_target_dsm_corr_measure, cosmo_searchlight,
%           cosmo_dim_transpose
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults=struct();
    defaults.radius=0;
    defaults.progress=1;
    defaults.check_partitions=false;
    defaults.nproc=1;
    opt=cosmo_structjoin(defaults,varargin);

    cosmo_check_dataset(ds);
    check_input(ds,opt);

    % get training and test set
    halves=split_dataset_in_train_and_test(ds);

    % split the data in two halves
    [train_values,train_splits]=split_half_by_dimension(halves{1},opt);
    [test_values,test_splits]=split_half_by_dimension(halves{2},opt);

    halves=[]; % let GC do its work
    
    % get number of processes available
    nproc_available=cosmo_parallel_get_nproc_available(opt);
    
    % Matlab needs newline character at progress message to show it in
    % parallel mode; Octave should not have newline character
    environment=cosmo_wtf('environment');
    progress_suffix=get_progress_suffix(environment);
        
    % split training data in multiple parts, so that each thread can do a
    % subset of all the work
    % set options for each worker process
    worker_opt_cell=cell(1,nproc_available);
    block_size=ceil(length(train_values)/nproc_available);
    first=1;
    for p=1:nproc_available
        last=min(first+block_size-1,length(train_values));
        block_idxs=first:last;
        
        worker_opt=struct();
        worker_opt.train_splits=train_splits(block_idxs);
        worker_opt.train_values=train_values(block_idxs);
        worker_opt.train_values_ori=train_values;
        worker_opt.train_values_idx=block_idxs;
        worker_opt.test_splits=test_splits;
        worker_opt.test_values=test_values;
        worker_opt.opt=opt;
        worker_opt.worker_id=p;
        worker_opt.nworkers=nproc_available;
        worker_opt.progress=opt.progress;
        worker_opt.progress_suffix=progress_suffix;
        worker_opt_cell{p}=worker_opt;
        first=last+1;
    end

    % Run process for each worker in parallel
    % Note that when using nproc=1, cosmo_parcellfun does actually not
    % use any parallellization; the result is a cell with a single element.
    result_map_cell=cosmo_parcellfun(opt.nproc,...
                                     @run_with_worker,...
                                    worker_opt_cell,...
                                    'UniformOutput',false);
    
    result=cosmo_stack(result_map_cell,1);
    cosmo_check_dataset(result);
    
    
function result=run_with_worker(worker_opt)
% run dimgen using the options in worker_opt

    train_splits = worker_opt.train_splits;
    train_values = worker_opt.train_values;
    train_values_ori = worker_opt.train_values_ori;
    train_values_idx = worker_opt.train_values_idx;
    test_splits = worker_opt.test_splits;
    test_values = worker_opt.test_values;
    opt = worker_opt.opt;
    worker_id=worker_opt.worker_id;
    nworkers=worker_opt.nworkers;
    progress=worker_opt.progress;
    progress_suffix=worker_opt.progress_suffix;
    
    % set partitions in case a crossvalidation or correlation measure is
    % used
    ntrain_elem=cellfun(@(x)size(x.samples,1),train_splits);
    ntest_elem=cellfun(@(x)size(x.samples,1),test_splits);
    opt.partitions=struct();
    opt.partitions.train_indices=cell(1);
    opt.partitions.test_indices=cell(1);

    % remove the dimension and measure arguments from the input
    dimension=opt.dimension;
    measure=opt.measure;

    opt=rmfield(opt,'dimension');
    opt=rmfield(opt,'measure');

    train_label=['train_' dimension];
    test_label=['test_' dimension];

    % see if progress has to be shown
    show_progress=~isempty(progress) && ...
                        progress && ...
                        worker_id==1;
    if show_progress
        prev_progress_msg='';
        clock_start=clock();
    end

    % allocate space for output
    ntrain=numel(train_values);
    ntest=numel(test_values);

    result_cell=cell(ntrain*ntest,1);

    % last non-empty row in result_cell
    pos=0;

    for k=1:ntrain
        % update partitions train set
        opt.partitions.train_indices{1}=1:ntrain_elem(k);
        for j=1:ntest
            % update partitions test set
            opt.partitions.test_indices{1}=ntrain_elem(k)+...
                                                (1:ntest_elem(j));
            % merge training and test dataset
            ds_merged=cosmo_stack({train_splits{k},test_splits{j}},...
                                                        1,1,false);

            opt.partitions=cosmo_balance_partitions(opt.partitions,...
                                            ds_merged,opt);

            % apply measure
            ds_result=measure(ds_merged,opt);

            % set dimension attributes
            nsamples=size(ds_result.samples,1);
            ds_result.sa.(train_label)=repmat(train_values_idx(k),...
                                            nsamples,1);
            ds_result.sa.(test_label)=repmat(j,nsamples,1);

            % store result
            pos=pos+1;
            result_cell{pos}=ds_result;
        end

        if show_progress
            if nworkers>1
                if k==ntrain
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
                            k/ntrain, msg, prev_progress_msg);
        end

    end

    % merge results into a dataset
    result=cosmo_stack(result_cell,1,'drop_nonunique');
    if isfield(result,'sa') && isfield(result.sa,dimension)
        result.sa=rmfield(result.sa,dimension);
    end

    % set dimension attributes in the sample dimension
    result=add_sample_attr(result, {train_label;test_label},...
                                    {train_values_ori;test_values});



function check_input(ds,opt)
    % ensure input is kosher
    cosmo_isfield(opt,{'dimension','measure'},true);

    dimension=opt.dimension;
    dim_pos=cosmo_dim_find(ds,dimension,true);
    if dim_pos~=1
        error(['''%s'' must be a sample dimension (not a feature) '...
                    'dimension. To make ''%s'' a sample dimension in '...
                    'a dataset struct ds, use\n\n'...
                    '  cosmo_dim_transpose(ds,''%s'',1);'],...
                    dimension,dimension,dimension);
    end

    measure=opt.measure;
    if ~isa(measure,'function_handle')
        error('the ''measure'' argument must be a function handle');
    end

    if isfield(opt,'partitions')
        error(['the partitions argument is not allowed for this '...
                    'function, because it generates partitions itself.'...
                    'The dataset should have two chunks, with '...
                    'chunks set to 1 for the training set and '...
                    'set to 2 for the testing set']);
    end

function halves=split_dataset_in_train_and_test(ds)
    % return cell with {train_ds,test_ds}
    halves=cosmo_split(ds,'chunks',1);
    if numel(halves)~=2 || ...
            halves{1}.sa.chunks(1)~=1 || ...
            halves{2}.sa.chunks(1)~=2
        error(['chunks must be 1 (for the training set) or 2'...
                '(for the testing set)' ]);
    end

function [values,splits]=split_half_by_dimension(ds,opt)
    % split dataset by ds.a.(opt.dimension)
    dimension=opt.dimension;
    ds_pruned=cosmo_dim_prune(ds,'labels',{dimension},'dim',1);
    ds_tr=cosmo_dim_transpose(ds_pruned,dimension,2);

    nbrhood=cosmo_interval_neighborhood(ds_tr,dimension,opt);
    assert(isequal(nbrhood.a.fdim.labels,{dimension}));

    counts=cellfun(@numel,nbrhood.neighbors);

    keep_nbrs=find(counts==max(counts));

    % remove dimension information
    ds_tr=remove_fa_field(ds_tr,dimension);

    values=nbrhood.a.fdim.values{1}(keep_nbrs);
    sz=size(values);
    if sz(1)==1
        values=values';
    elseif sz(2)~=1
        error('dimension %s must be a row vector', dimension);
    end

    n=numel(keep_nbrs);
    splits=cell(n,1);

    for k=1:n
        idx=nbrhood.neighbors{keep_nbrs(k)};
        splits{k}=cosmo_slice(ds_tr,idx,2,false);
    end


function ds=add_sample_attr(ds, dim_labels, dim_values)
    if ~isfield(ds,'a') || ~isfield(ds.a,'sdim')
        ds.a.sdim=struct();
        ds.a.sdim.labels=cell(1,0);
        ds.a.sdim.values=cell(1,0);
    end


    ds.a.sdim.values=[ds.a.sdim.values(:); dim_values]';
    ds.a.sdim.labels=[ds.a.sdim.labels(:); dim_labels]';


function ds=remove_fa_field(ds,label)
    if isfield(ds.fa,label);
        ds.fa=rmfield(ds.fa,label);
    end

    [dim, index, attr_name, dim_name]=cosmo_dim_find(ds,...
                                                label,false);
    if ~isempty(dim)
        sfdim=ds.a.(dim_name);
        m=~cosmo_match(sfdim.labels,label);
        sfdim.values=sfdim.values(m);
        sfdim.labels=sfdim.labels(m);
        ds.a.(dim_name)=sfdim;
    end

function suffix=get_progress_suffix(environment)
    % Matlab needs newline character at progress message to show it in
    % parallel mode; Octave should not have newline character

    switch environment
        case 'matlab'
            suffix=sprintf('\n');
        case 'octave'
            suffix='';
    end
