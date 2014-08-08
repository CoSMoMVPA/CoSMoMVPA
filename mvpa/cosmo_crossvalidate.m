function [pred, accuracy] = cosmo_crossvalidate(ds, classifier, partitions, opt)
% performs cross-validation using a classifier
%
% [pred, accuracy] = cosmo_crossvalidate(dataset, classifier, partitions, opt)
%
% Inputs
%   ds                  struct with fields .samples (PxQ for P samples and
%                       Q features) and .sa.targets (Px1 labels of samples)
%   classifier          function handle to classifier, e.g.
%                       @classify_naive_baysian
%   partitions          For example the output from nfold_partition
%   opt                 optional struct with options for classifier
%     .normalization    optional, one of '{zscore,demean,scale_unit}{1,2}'
%                       to normalize the data prior to classification using
%                       zscoring, demeaning or scaling to [-1,1] along the
%                       first or second dimension of ds. Normalization
%                       parameters are estimated using the training data
%                       and applied to the testing data.
%    .check_partitions  optional (default: true). If set to false then
%                       partitions are not checked for being set properly.
%
% Output
%   pred                Qx1 array with predicted class labels
%
% NNO Aug 2013
    if nargin<4,opt=struct(); end
    if ~isfield(opt, 'normalization'), opt.normalization=[]; end
    if ~isfield(opt, 'check_partitions'), opt.check_partitions=true; end

    if ~isempty(opt.normalization);
        normalization=opt.normalization;
    else
        normalization=[];
    end

    if opt.check_partitions
        cosmo_check_partitions(partitions, ds);
    end

    train_indices = partitions.train_indices;
    test_indices = partitions.test_indices;

    npartitions=numel(train_indices);

    nsamples=size(ds.samples,1);

    % space for output (one column per partition)
    % the k-th column contains predictions for the k-th partition
    % (with values of zeros if there was no prediction)
    all_pred=zeros(nsamples,npartitions);

    targets=ds.sa.targets;

    % keep track for which samples there has been a prediction
    test_mask=false(nsamples,1);

    % process each fold
    for k=1:npartitions
        train_idxs=train_indices{k};
        test_idxs=test_indices{k};
        % for each partition get the training and test data, store in
        % train_data and test_data
        % >@@>
        train_data = ds.samples(train_idxs,:);
        test_data = ds.samples(test_idxs,:);
        % <@@<

        % apply normalization
        if ~isempty(normalization)
            [train_data,params]=cosmo_normalize(train_data,normalization);
            test_data=cosmo_normalize(test_data,params);
        end

        % >@@>
        % then get predictions for the training samples using
        % the classifier, and store these in the k-th column of all_pred.

        train_targets = targets(train_idxs);
        p = classifier(train_data, train_targets, test_data, opt);

        all_pred(test_idxs,k) = p;
        test_mask(test_idxs)=true;
        % <@@<
    end

    % combine predictions for multiple partitions
    % - in the case of nfold-crossvalidation there is just one prediction
    %   for each sample, but with other cross validation schemes such as
    %   from nchoosek_partitioner(ds, 2) there can be more than one.
    [pred,classes]=cosmo_winner_indices(all_pred);

    % compute accuracies
    correct_mask=ds.sa.targets(test_mask)==classes(pred(pred>0));
    ncorrect = sum(correct_mask);
    ntotal = numel(correct_mask);

    accuracy = ncorrect/ntotal;
