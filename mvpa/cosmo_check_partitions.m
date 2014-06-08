function cosmo_check_partitions(partitions, ds, varargin)
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
%
% Throws: 
%   - an error if partitions are double dippy or (unless specified in opt)
%     not balanced
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
    if ~isfield(ds,'sa') || ~isfield(ds.sa,'targets') || ...
            ~isfield(ds.sa,'targets')
        error('dataset requires .sa.{chunks,targets}');
    end
    
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
    
    for k=1:npartitions
        train_idxs=train_indices{k};
        test_idxs=test_indices{k}; 

        if check_balance
            % counts of number of samples in each each class must be the
            % same
            train_classes=sample2class(train_idxs);
            h=histc(train_classes,1:numel(classes));
            if ~all(h(1)==h)
                idx=find(h(1)~=h,1);
                error(['Unbalance in partition %d, classes %d (#=%d) '...
                        'and %d (#=%d). Balance the partitions '...
                        'using cosmo_balance_partitions, or, if you '...
                        '*really* know what you are doing, set '...
                        'unbalanced_partitions_ok to true as option'], ...
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