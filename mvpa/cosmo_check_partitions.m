function is_ok=cosmo_check_partitions(partitions, ds, varargin)
% check whether partitions are balanced and not double-dippy
%
% cosmo_check_partitions(partitions, ds, varargin)
%
% Inputs:
%   ds          dataset struct with fields .sa.{targets,chunks}
%   partitions  struct with partitions, e.g. from
%               cosmo_{nfold,oddeven,nchoosek}_partitioner
%   opt         (optional) struct with optional field:
%     .unbalanced_partitions_ok    if set to true, then unbalanced
%                                  partitions (with a different number of
%                                  targets of each class in a chunk) is ok
% Output:
%    is_ok      boolean, true if partitions are ok
%
% Throws:
%   - an error if partitions are double dippy or (unless specified in opt)
%     not balanced
%
% Examples:
%     ds=struct();
%     ds.samples=zeros(9,2);
%     ds.sa.targets=[1 1 2 2 2 3 3 3 3]';
%     ds.sa.chunks=[1 2 2 1 1 1 2 2 2]';
%     % make unbalanced partitions
%     partitions=cosmo_nfold_partitioner(ds);
%     cosmo_check_partitions(partitions,ds);
%     > error('Unbalance in partition 1 [...]')
%     %
%     % disable unbalanced check
%     cosmo_check_partitions(partitions,ds,'unbalanced_partitions_ok',true)
%     > true
%     %
%     % balance partitions and check without unbalanced check
%     partitions=cosmo_balance_partitions(partitions,ds);
%     cosmo_check_partitions(partitions,ds,'unbalanced_partitions_ok',false)
%     > true
%     %
%     % make the partitions double dippy
%     partitions.train_indices{1}=partitions.test_indices{1};
%     cosmo_check_partitions(partitions,ds,'unbalanced_partitions_ok',true)
%     > error('double dipping in fold 1: chunk 1 is in train and test set')
%     %
%     % make partitions empty
%     partitions.train_indices{1}=[];
%     cosmo_check_partitions(partitions,ds);
%     > error('partition 1: .train_indices are empty')
%     %
%     % partitions have values outside range
%     partitions.train_indices{1}=100;
%     cosmo_check_partitions(partitions,ds);
%     > error('partition 1: .train_indices are outside range 1..9');
%     %
%     % use non-integers
%     partitions.train_indices{1}=1.5;
%     cosmo_check_partitions(partitions,ds);
%     > error('partition 1: .train_indices are not integers');
%
% Notes:
%   - the reason to require balancing by default is that chance level is
%     1/nclasses, which is useful for many subsequent analyses.
%   - if this function raises an exception for partitions, consider running
%     partitions=cosmo_balance_partitions(partitions,...).
%
% See also: cosmo_balance_partitions, cosmo_nfold_partitioner
%
% NNO Jan 2014

    is_ok=false;

    % process input arguments
    defaults=struct();
    defaults.unbalanced_partitions_ok=false;

    params=cosmo_structjoin(defaults,varargin{:});

    % whether to check for equal number of samples of each class in
    % each chunks
    check_balance=~params.unbalanced_partitions_ok;

    % whether to check for the same chunk in train and test set
    check_double_dipping=true;

    % check dataset
    cosmo_check_dataset(ds);

    % ensure it has targets and chunks
    targets=ds.sa.targets;
    chunks=ds.sa.chunks;

    if check_balance
        [classes,unused,sample2class]=unique(targets);
    end

    % ensure equal number of partitions for train and test
    train_indices=partitions.train_indices;
    test_indices=partitions.test_indices;

    npartitions=numel(train_indices);
    if npartitions~=numel(test_indices)
        error('Partition count mismatch for train and test: %d ~= %d',...
                    npartitions,numel(test_indices));
    end

    nsamples=numel(targets);

    for k=1:npartitions
        train_idxs=train_indices{k};
        test_idxs=test_indices{k};

        check_range(train_idxs,nsamples,k,'train');
        check_range(test_idxs,nsamples,k,'test');

        if check_balance
            % counts of number of samples in each each class must be the
            % same
            train_classes=sample2class(train_idxs);
            h=histc(train_classes,1:numel(classes));
            if ~all(h(1)==h)
                idx=find(h(1)~=h,1);
                error(['Unbalance in partition %d, '...
                     'classes %d (#=%d) and %d (#=%d). '...
                     'Consider the following scenarios:\n'...
                     '(1) the input is an MEEG dataset, or an fMRI '...
                     'dataset with missing samples (trials) in some '...
                     'of the runs. You probably want to use '...
                     'cosmo_balance_partitions.\n'...
                     '(2) the input is an fMRI dataset using beta '...
                     'estimates or t-statistics estimated using the '...
                     'GLM, with one sample '...
                     'of each condition per run (e.g. nfold partition) '...
                     'or per set of runs (e.g. odd-even partition). '...
                     'Probably a mistake was made setting .sa.chunks '...
                     'or .sa.targets\n'...
                     '(3) you *really* know what you are doing: '...
                     'as a litmus test, you would be comfortable '...
                     'implementing a bootstrapping algorithm to '...
                     'estimate the cdf of your measure of interest '...
                     'under some null hypothesis. You can set '...
                     'unbalanced_partitions_ok to true as an option'],...
                      k, classes(1), h(1), classes(idx), h(idx));
            end
        end

        if check_double_dipping
            % no sample allowed to be both in train and test indices
            if any(cosmo_match(chunks(train_idxs),chunks(test_idxs)))
                ctrain=chunks(train_idxs);
                m=cosmo_match(ctrain,chunks(test_idxs));
                idx=find(m,1);

                error(['double dipping in fold %d: chunk %d is in '...
                       'train and test set'],k,ctrain(idx));
            end
        end
    end

    is_ok=true;

function check_range(idxs,nsamples,partition,label)
    if isempty(idxs)
        return;
    end
    msg='';
    if ~isequal(idxs,round(idxs))
        msg='not integers';
    elseif min(idxs)<1 || max(idxs)>nsamples
        msg=sprintf('outside range 1..%d',nsamples);
    end

    if ~isempty(msg)
        error('partition %d: .%s_indices are %s',partition,label,msg);
    end
