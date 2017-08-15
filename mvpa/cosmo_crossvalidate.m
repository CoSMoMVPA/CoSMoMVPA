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
%     .normalization    optional, one of 'zscore','demean','scale_unit'
%                       to normalize the data prior to classification using
%                       zscoring, demeaning or scaling to [-1,1] along the
%                       first dimension of ds. Normalization
%                       parameters are estimated using the training data
%                       and applied to the testing data.
%     .pca_explained_count   optional, transform the data with PCA prior to
%                            classification, and retain this number of
%                            components
%     .pca_explained_ratio   optional, transform the data with PCA prior to
%                            classification, and retain the components that
%                            explain this percentage of the variance
%                            (value between 0-1)
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
%     [pred,accuracy]=cosmo_crossvalidate(ds, classifier, ...
%                                                       partitions);
%     % show targets, chunks, and predictions labels for each of the
%     % four folds
%     cosmo_disp({ds.sa.targets,ds.sa.chunks,pred},'threshold',inf)
%     %|| { [ 3    [ 1    [   3   NaN   NaN   NaN
%     %||     4      1        4   NaN   NaN   NaN
%     %||     5      1        5   NaN   NaN   NaN
%     %||     3      2      NaN     3   NaN   NaN
%     %||     4      2      NaN     5   NaN   NaN
%     %||     5      2      NaN     5   NaN   NaN
%     %||     3      3      NaN   NaN     3   NaN
%     %||     4      3      NaN   NaN     4   NaN
%     %||     5      3      NaN   NaN     5   NaN
%     %||     3      4      NaN   NaN   NaN     3
%     %||     4      4      NaN   NaN   NaN     4
%     %||     5 ]    4 ]    NaN   NaN   NaN     5 ] }
%     cosmo_disp(accuracy)
%     %||  0.917
%     %
%     % use take-2-chunks out for testing crossvalidation, LDA classifier
%     partitions=cosmo_nchoosek_partitioner(ds,2);
%     classifier=@cosmo_classify_lda;
%     % run crossvalidation
%     [pred,accuracy]=cosmo_crossvalidate(ds, classifier, ...
%                                                           partitions);
%     % show targets, chunks, and predictions labels for each of the
%     % four folds
%     cosmo_disp({ds.sa.targets,ds.sa.chunks,pred},'threshold',inf)
%     %|| { [ 3    [ 1    [   5     5     3   NaN   NaN   NaN
%     %||     4      1        4     4     4   NaN   NaN   NaN
%     %||     5      1        5     5     4   NaN   NaN   NaN
%     %||     3      2        3   NaN   NaN     3     3   NaN
%     %||     4      2        4   NaN   NaN     4     4   NaN
%     %||     5      2        5   NaN   NaN     4     5   NaN
%     %||     3      3      NaN     5   NaN     3   NaN     3
%     %||     4      3      NaN     4   NaN     4   NaN     4
%     %||     5      3      NaN     5   NaN     5   NaN     5
%     %||     3      4      NaN   NaN     3   NaN     3     3
%     %||     4      4      NaN   NaN     4   NaN     4     5
%     %||     5 ]    4 ]    NaN   NaN     5   NaN     3     3 ] }
%     cosmo_disp(accuracy)
%     %||   0.778
%     %
%     % as the example above, but (1) use z-scoring on each training set
%     % and apply the estimated mean and std to the test set, and (2)
%     % use odd-even partitioner
%     opt=struct();
%     opt.normalization='zscore';
%     partitions=cosmo_oddeven_partitioner(ds);
%     % run crossvalidation
%     [pred,accuracy]=cosmo_crossvalidate(ds, classifier, ...
%                                                        partitions, opt);
%     % show targets, predicted labels, and accuracy
%     cosmo_disp({ds.sa.targets,ds.sa.chunks,pred},'threshold',inf)
%     %|| { [ 3    [ 1    [ NaN     5
%     %||     4      1      NaN     4
%     %||     5      1      NaN     5
%     %||     3      2        3   NaN
%     %||     4      2        4   NaN
%     %||     5      2        5   NaN
%     %||     3      3      NaN     5
%     %||     4      3      NaN     4
%     %||     5      3      NaN     5
%     %||     3      4        3   NaN
%     %||     4      4        4   NaN
%     %||     5 ]    4 ]      3   NaN ] }
%     cosmo_disp(accuracy)
%     %||   0.75
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

    if all(isfield(opt, {'pca_explained_count','pca_explained_ratio'}))
            error(['pca_explained_count and pca_explained_ratio are ' ...
                'mutually exclusive'])
    elseif isfield(opt, 'pca_explained_count');
        arg_pca='pca_explained_count';
        arg_pca_value=opt.pca_explained_count;
    elseif isfield(opt, 'pca_explained_ratio');
        arg_pca='pca_explained_ratio';
        arg_pca_value=opt.pca_explained_ratio;
    else
        arg_pca=[];
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
    % the k-th column contains predictions for the k-th fold
    % (with values of NaNs if there was no prediction)
    pred=NaN(nsamples,npartitions);

    targets=ds.sa.targets;

    % process each fold
    for fold=1:npartitions
        train_idxs=train_indices{fold};
        test_idxs=test_indices{fold};
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

        % apply pca
        if ~isempty(arg_pca)
            [train_data,pca_params]=cosmo_map_pca(train_data,...
                    arg_pca,arg_pca_value);
            test_data=cosmo_map_pca(test_data,'pca_params',pca_params);
        end

        % apply normalization
        if ~isempty(normalization)
            [train_data,params]=cosmo_normalize(train_data,normalization);
            test_data=cosmo_normalize(test_data,params);
        end

        % then get predictions for the training samples using
        % the classifier, and store these in the k-th column of all_pred.
        p = classifier(train_data, train_targets, test_data, opt);

        pred(test_idxs,fold) = p;
    end

    % compute accuracies
    has_prediction_mask=~isnan(pred);
    correct_mask=bsxfun(@eq,targets,pred) & has_prediction_mask;

    accuracy=sum(correct_mask)/sum(has_prediction_mask);

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



