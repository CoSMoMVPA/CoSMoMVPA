function bal_partitions=cosmo_balance_partitions(partitions,ds, varargin)
% balances a partition so that each target occurs equally often in each
% training chunk
%
% bpartitions=cosmo_balance_partitions(partitions, ds, ...)
%
% Inputs:
%   partitions        struct with fields:
%     .train_indices  } Each is a 1xN cell (for N chunks) containing the
%     .test_indices   } sample indices for each partition
%   ds                dataset struct with field .sa.targets.
%   'nrepeats',nr     Number of repeats (default: 1). The output will
%                     have nrep as many partitions as the input set. This
%                     option, if provided, is not compatible with 'nmin'.
%   'nmin',nm         Ensure that each sample occurs at least
%                     nmin times in each training set (some samples may
%                     be repeated more often than than). This option, if
%                     provided, is not compatible with 'nrepeats'.
%
% Ouput:
%   bpartitions    similar struct as input partitions, except that
%                  - each field is a 1x(N*nsets) cell
%                  - each unique target is represented about equally often
%                  - each target in each training chunk occurs equally
%                    often
%
% Examples:
%     % generate a simple dataset with unbalanced partitions
%     ds=struct();
%     ds.samples=zeros(9,2);
%     ds.sa.targets=[1 1 2 2 2 3 3 3 3]';
%     ds.sa.chunks=[1 2 2 1 1 1 2 2 2]';
%     p=cosmo_nfold_partitioner(ds);
%     %
%     % show original (unbalanced) partitioning
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 2    [ 1
%     >       3      4
%     >       7      5
%     >       8      6 ]
%     >       9 ]        }
%     > .test_indices
%     >   { [ 1    [ 2
%     >       4      3
%     >       5      7
%     >       6 ]    8
%     >              9 ] }
%     %
%     % make standard balancing (nsets=1); some targets are not used
%     q=cosmo_balance_partitions(p,ds);
%     cosmo_disp(q);
%     > .train_indices
%     >   { [ 2    [ 1
%     >       3      5
%     >       7 ]    6 ] }
%     > .test_indices
%     >   { [ 1    [ 2
%     >       4      3
%     >       5      7
%     >       6 ]    8
%     >              9 ] }
%     %
%     % make balancing where each sample in each training fold is used at
%     % least once
%     q=cosmo_balance_partitions(p,ds,'nmin',1);
%     cosmo_disp(q);
%     > .train_indices
%     >   { [ 2    [ 2    [ 2    [ 1    [ 1
%     >       3      3      3      5      4
%     >       7 ]    9 ]    8 ]    6 ]    6 ] }
%     > .test_indices
%     >   { [ 1    [ 1    [ 1    [ 2    [ 2
%     >       4      4      4      3      3
%     >       5      5      5      7      7
%     >       6 ]    6 ]    6 ]    8      8
%     >                            9 ]    9 ] }
%     %
%     % triple the number of partitions and sample from training indices
%     q=cosmo_balance_partitions(p,ds,'nrepeats',3);
%     cosmo_disp(q);
%     > .train_indices
%     >   { [ 2    [ 2    [ 2    [ 1    [ 1    [ 1
%     >       3      3      3      5      4      5
%     >       7 ]    9 ]    8 ]    6 ]    6 ]    6 ] }
%     > .test_indices
%     >   { [ 1    [ 1    [ 1    [ 2    [ 2    [ 2
%     >       4      4      4      3      3      3
%     >       5      5      5      7      7      7
%     >       6 ]    6 ]    6 ]    8      8      8
%     >                            9 ]    9 ]    9 ] }
%
% Notes:
% - this function is intended for datasets where the number of
%   samples across targets is not equally distributed. A typical
%   application is MEEG datasets.
% - Using this function means that chance accuracy is equal to the inverse
%   of the number of unique targets.
% - This function balances the training indices only, not the test_indices.
%   Test_indices may be repeated
%
% See also: cosmo_nchoosek_partitioner, cosmo_nfold_partitioner
%
% NNO Dec 2013

    defaults=struct();
    defaults.nrep=1;
    defaults.seed=1;
    params=cosmo_structjoin(defaults,varargin);

    cosmo_check_partitions(partitions,ds,'unbalanced_partitions_ok',true);

    classes=unique(ds.sa.targets);

    nfolds_in=numel(partitions.train_indices);

    train_indices_out=cell(1,nfolds_in);
    test_indices_out=cell(1,nfolds_in);

    for j=1:nfolds_in
        tr_idx=partitions.train_indices{j};
        te_idx=partitions.test_indices(j);
        targets=ds.sa.targets(tr_idx);
        [fold_classes,fold_class_pos]=get_classes(targets);

        if ~isequal(fold_classes,classes)
            missing=setdiff(classes,fold_classes);
            error('missing class %d in fold %d', missing(1), j);
        end

        % see how many output folds for the current input fold
        nfolds_out=get_nfolds_out(fold_class_pos,params);

        % sample from the indices
        folds_out=sample_class_pos(fold_class_pos,nfolds_out,params);

        % assing training indices
        tr_folds_out=cell(1,nfolds_out);
        for k=1:nfolds_out
            tr_folds_out{k}=tr_idx(folds_out{k});
        end
        train_indices_out{j}=tr_folds_out;

        % copy test indices
        test_indices_out{j}=repmat(te_idx,1,nfolds_out);
    end

    bal_partitions=struct();
    bal_partitions.train_indices=cat(2,train_indices_out{:});
    bal_partitions.test_indices=cat(2,test_indices_out{:});



function [classes,class_pos]=get_classes(targets)
    [class_pos,targets_cell]=cosmo_index_unique({targets});
    classes=targets_cell{1};


function nfolds=get_nfolds_out(class_pos,params)
    % return how many folds are needed based on the sample indices for each
    % class
    if isfield(params,'nmin')
        if isfield(params,'nrepeats')
            error(['options ''nmin'' and nrepeat'' are '...
                        'mutually exclusive']);
        else
            targets_hist=cellfun(@numel,class_pos);
            nsamples_ratio=max(targets_hist)/min(targets_hist);
            nfolds=ceil(nsamples_ratio)*params.nmin;
        end
    elseif isfield(params,'nrepeats')
        nfolds=params.nrepeats;
    else
        nfolds=1;
    end


function folds=sample_class_pos(class_pos,nfolds,params)
    % return nfolds folds, each with a sample from class_pos
    nclasses=numel(class_pos);
    class_count=cellfun(@numel,class_pos);
    nsamples_per_class=min(class_count);
    boundaries=[0;cumsum(class_count)];
    nsamples=boundaries(end);

    % single call to generate pseudo-random uniform data
    uniform_random_all=cosmo_rand(nsamples,1,'seed',params.seed);
    idxs=cell(nfolds,nclasses);

    % process each fold seperately
    for k=1:nclasses
        uniform_random_pos=(boundaries(k)+1):boundaries(k+1);
        [foo,i]=sort(uniform_random_all(uniform_random_pos));
        nrepeats=ceil(nsamples_per_class*nfolds/numel(i));

        % build sequence by repeating the random indices as many times as
        % necessary
        seq=repmat(i,1,nrepeats);

        for j=1:nfolds
            if k==1
                idxs{j}=cell(1,nclasses);
            end

            seq_idx=nsamples_per_class*(j-1)+(1:nsamples_per_class);
            idxs{j,k}=class_pos{k}(seq(seq_idx));
        end
    end

    folds=cell(1,nfolds);
    for j=1:nfolds
        folds{j}=cat(1,idxs{j,:});
    end

