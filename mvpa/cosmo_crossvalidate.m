function [pred, accuracy, test_chunks] = cosmo_crossvalidate(ds, classifier, partitions, opt)
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
%    .average_train_X   average the samples in the train set using
%                       cosmo_average_samples. For X, use any parameter
%                       supported by cosmo_average_samples, i.e. either
%                       'count' or 'ratio', and optionally, 'resamplings'
%                       or 'repeats'.
%
% Output
%   pred                Qx1 array with predicted class labels.
%                       elements with no predictions have the value NaN.
%   accuracy            scalar classification accuracy
%   test_chunks         Qx1 array with chunks of input dataset, if each
%                       prediction was based using a single classification
%                       step. Predictions with no or more than one
%                       classification step are set to NaN
%
% Examples:
%     % generate dataset with 3 targets and 4 chunks, first target is 3
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4,'target1',3);
%     % use take-1-chunk for testing crossvalidation
%     partitions=cosmo_nfold_partitioner(ds);
%     classifier=@cosmo_classify_naive_bayes;
%     % run crossvalidation
%     [pred,accuracy,chunks]=cosmo_crossvalidate(ds, classifier, ...
%                                                       partitions);
%     % show targets, predicted labels, and accuracy
%     disp([ds.sa.targets pred chunks])
%     >      3     3     1
%     >      4     4     1
%     >      5     5     1
%     >      3     3     2
%     >      4     5     2
%     >      5     5     2
%     >      3     3     3
%     >      4     4     3
%     >      5     5     3
%     >      3     3     4
%     >      4     4     4
%     >      5     5     4
%     disp(accuracy)
%     >     0.9167
%     %
%     % use take-2-chunks out for testing crossvalidation, LDA classifier
%     partitions=cosmo_nchoosek_partitioner(ds,2);
%     classifier=@cosmo_classify_lda;
%     % run crossvalidation
%     [pred,accuracy,chunks]=cosmo_crossvalidate(ds, classifier, ...
%                                                           partitions);
%     % show targets, predicted labels, and accuracy
%     % (chunks are set to NaN because there is no unique chunk for
%     %  each prediction)
%     disp([ds.sa.targets pred chunks])
%     >      3     5   NaN
%     >      4     4   NaN
%     >      5     5   NaN
%     >      3     3   NaN
%     >      4     4   NaN
%     >      5     5   NaN
%     >      3     3   NaN
%     >      4     4   NaN
%     >      5     5   NaN
%     >      3     3   NaN
%     >      4     4   NaN
%     >      5     3   NaN
%     disp(accuracy)
%     >     0.8333
%     %
%     % as the example above, but use z-scoring on each training set
%     % and apply the estimated mean and std to the test set.
%     opt=struct();
%     opt.normalization='zscore';
%     partitions=cosmo_oddeven_partitioner(ds);
%     % run crossvalidation
%     [pred,accuracy,chunks]=cosmo_crossvalidate(ds, classifier, ...
%                                                        partitions, opt);
%     % show targets, predicted labels, and accuracy
%     disp([ds.sa.targets pred chunks])
%     >      3     5     1
%     >      4     4     1
%     >      5     5     1
%     >      3     3     2
%     >      4     4     2
%     >      5     5     2
%     >      3     5     3
%     >      4     4     3
%     >      5     5     3
%     >      3     3     4
%     >      4     4     4
%     >      5     3     4
%     disp(accuracy)
%     >     0.7500
%
% Notes:
%   - to apply this to a dataset struct as a measure (for searchlights),
%     consider using cosmo_crossvalidation_measure
%   - to average samples in the training set prior to training, use the
%     options provided by cosmo_average_samples prefixed by
%     'average_train_'. For example, to take averages of 5 samples, and use
%     each sample in the input approximately 4 times, use:
%           opt.average_train_count=5;
%           opt.average_train_resamplings=4;
%
% See also: cosmo_crossvalidation_measure, cosmo_average_samples
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<4,opt=struct(); end
    if ~isfield(opt, 'normalization'),
        opt.normalization=[];
    end
    if ~isfield(opt, 'check_partitions'),
        opt.check_partitions=true;
    end

    if ~isempty(opt.normalization);
        normalization=opt.normalization;
        opt.autoscale=false; % disable for {matlab,lib}svm classifiers
    else
        normalization=[];
    end

    if opt.check_partitions
        cosmo_check_partitions(partitions, ds);
    end

    % see if samples in training set are to be averaged
    [do_average_train, average_train_opt]=get_average_train_opt(opt);

    train_indices = partitions.train_indices;
    test_indices = partitions.test_indices;

    npartitions=numel(train_indices);

    nsamples=size(ds.samples,1);

    % space for output (one column per partition)
    % the k-th column contains predictions for the k-th partition
    % (with values of zeros if there was no prediction)
    all_pred=NaN(nsamples,npartitions);

    targets=ds.sa.targets;
    chunks=ds.sa.chunks;

    % keep track for which samples there has been a prediction
    test_mask=false(nsamples,1);

    % keep track how often a prediction there was made for each chunk
    test_chunks=NaN(nsamples,1);
    test_counts=zeros(nsamples,1);

    % process each fold
    for k=1:npartitions
        train_idxs=train_indices{k};
        test_idxs=test_indices{k};
        % for each partition get the training and test data, store in
        % train_data and test_data
        train_data = ds.samples(train_idxs,:);
        train_targets = targets(train_idxs);

        if do_average_train
            % make a minimal dataset, then use cosmo_average_samples to
            % compute averages
            n_train=numel(train_idxs);
            ds_train=struct();
            ds_train.samples=train_data;
            ds_train.sa.chunks=ones(n_train,1);
            ds_train.sa.targets=train_targets;

            ds_train_avg=cosmo_average_samples(ds_train,average_train_opt);
            train_data=ds_train_avg.samples;
            train_targets=ds_train_avg.sa.targets;
        end

        test_data = ds.samples(test_idxs,:);

        % apply normalization
        if ~isempty(normalization)
            [train_data,params]=cosmo_normalize(train_data,normalization);
            test_data=cosmo_normalize(test_data,params);
        end



        % >@@>
        % then get predictions for the training samples using
        % the classifier, and store these in the k-th column of all_pred.
        p = classifier(train_data, train_targets, test_data, opt);

        all_pred(test_idxs,k) = p;
        test_mask(test_idxs)=true;
        % <@@<

        test_counts(test_idxs)=test_counts(test_idxs)+1;
        test_chunks(test_idxs)=chunks(test_idxs);
    end

    % combine predictions for multiple partitions
    % - in the case of nfold-crossvalidation there is just one prediction
    %   for each sample, but with other cross validation schemes such as
    %   from nchoosek_partitioner(ds, 2) there can be more than one.
    [pred_indices,classes]=cosmo_winner_indices(all_pred);

    % sanity check: missing predictions should be identical to lack of
    % winners
    assert(all(isnan(pred_indices)~=test_mask));
    assert(all(isnan(pred_indices)==isnan(test_chunks)));

    % only chunks with single prediction are not set to NaN
    test_chunks(test_counts~=1)=NaN;

    % set predictions
    pred=NaN(nsamples,1);
    pred(test_mask)=classes(pred_indices(test_mask));

    % compute accuracies
    correct_mask=ds.sa.targets(test_mask)==pred(test_mask);
    ncorrect = sum(correct_mask);
    ntotal = numel(correct_mask);

    accuracy = ncorrect/ntotal;

function [do_average_train, average_train_opt]=get_average_train_opt(opt)
    persistent cached_opt;
    persistent cached_do_average_train;
    persistent cached_average_train_opt;

    if ~isequal(cached_opt,opt)
        cached_average_train_opt=struct();
        cached_do_average_train=false;
        prefix='average_train_';
        keys=fieldnames(opt);
        for k=1:numel(keys)
            key=keys{k};
            sp=cosmo_strsplit(key,prefix);
            if isempty(sp{1})
                % starts with average_train, so take the rest of the key
                % and flag cached_do_average_train
                cached_average_train_opt.(sp{2})=opt.(key);
                cached_do_average_train=true;
            end
        end

        cached_opt=opt;
    end


    do_average_train=cached_do_average_train;
    average_train_opt=cached_average_train_opt;



