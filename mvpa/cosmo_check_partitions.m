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
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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
    check_dataset(ds);

    % ensure it has targets and chunks
    cosmo_isfield(ds,{'sa.targets','sa.chunks'},true);
    targets=ds.sa.targets;
    chunks=ds.sa.chunks;

    if check_balance
        [classes,unused,sample2class]=unique(targets);
    end

    % must have .train_indices and .test_indices
    cosmo_isfield(partitions,{'train_indices','test_indices'},true);
    train_indices=partitions.train_indices;
    test_indices=partitions.test_indices;

    if ~iscell(train_indices) || ~iscell(test_indices)
        error('.train_indices and .test_indices must be a cell');
    end

    % ensure equal number of partitions for train and test
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

            h_nonzero_idxs=find(h>0);
            if k==1
                first_h_nonzero_idxs=h_nonzero_idxs;
            elseif ~isequal(first_h_nonzero_idxs,h_nonzero_idxs);
                error(['Different targets used for training '...
                        'in partition %d and %d. This is weird. '...
                        'Consider the following scenarios:\n'...
                        '(1) You made the partitions manually. It is '...
                        'possible that you made a mistake.\n'...
                        '(2) You try to do cross-decoding and '...
                        'partitions were defined using '...
                        'cosmo_nchoosek_partitioner. This usually '...
                        'requires a *re-assignment* of .sa.targets '...
                        'so that the unique targets values are the '...
                        'same for the samples used for training '...
                        'and for testing. Please read the '...
                        'documentation of cosmo_nchoosek_partitioner '...
                        '(especially the examples) carefully and '...
                        'verify that '...
                        'the .sa.targets are (re)assigned properly.\n'...
                        '(3) You used a cosmo_ function to set the '...
                        'partitions, but case 2 does not apply. '...
                        'It may indicate a bug; in that case, '...
                        'please get in touch with the CoSMoMVPA '...
                        'developers'],1,k);
            end

            h_nonzero=h(h_nonzero_idxs);

            if ~all(h_nonzero(1)==h_nonzero)
                idx=find(h_nonzero(1)~=h_nonzero,1);

                pos_first=h_nonzero_idxs(1);
                pos_other=h_nonzero_idxs(idx);

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
                      k, classes(pos_first), h(pos_first), ...
                      classes(pos_other), h(pos_other));
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
    msg='';
    if isempty(idxs)
        msg='empty';
    elseif ~isequal(idxs,round(idxs))
        msg='not integers';
    elseif min(idxs)<1 || max(idxs)>nsamples
        msg=sprintf('outside range 1:%d',nsamples);
    end

    if ~isempty(msg)
        error('partition %d: .%s_indices are %s',partition,label,msg);
    end

function check_dataset(ds)
    persistent cached_sa;
    if isstruct(ds) && isfield(ds,'sa')
        if ~isequal(ds.sa,cached_sa)
            cosmo_check_dataset(ds);
            cached_sa=ds.sa;
        end
        return
    end

    error('second input must be a dataset struct with field .sa');






