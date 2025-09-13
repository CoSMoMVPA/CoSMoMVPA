function predicted = cosmo_classify_matlabcsvm(samples_train, targets_train, samples_test, opt)
    % svm classifier wrapper (around fitcsvm)
    %
    % predicted=cosmo_classify_matlabcsvm(samples_train, targets_train, samples_test, opt)
    %
    % Inputs:
    %   samples_train      PxR training data for P samples and R features
    %   targets_train      Px1 training data classes
    %   samples_test       QxR test data
    %   opt                struct with options. supports any option that
    %                      fitcsvm supports
    %
    % Output:
    %   predicted          Qx1 predicted data classes for samples_test
    %
    % Notes:
    %  - this function uses Matlab's builtin fitcsvm function, which was the
    %    successor of svmtrain.
    %  - Matlab's SVM classifier is rather slow, especially for multi-class
    %    data (more than two classes). When classification takes a long time,
    %    consider using libsvm.
    %  - for a guide on svm classification, see
    %      http://www.csie.ntu.edu.tw/~cjlin/papers/guide/guide.pdf
    %    Note that cosmo_crossvalidate and cosmo_crossvalidation_measure
    %    provide an option 'normalization' to perform data scaling
    %  - As of Matlab 2017a (maybe earlier), Matlab gives the warning that
    %      'svmtrain will be removed in a future release. Use fitcsvm instead.'
    %    however fitcsvm gives different results than svmtrain; as a result
    %    cosmo_classify_matlabcsvm gives different results than
    %    cosmo_classify_matlabsvm.
    %
    % See also fitcsvm, svmclassify, cosmo_classify_matlabsvm.
    %
    % #   For CoSMoMVPA's copyright information and license terms,   #
    % #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin < 4
        opt = struct();
    end

    [ntrain, nfeatures] = size(samples_train);
    [ntest, nfeatures_] = size(samples_test);
    ntrain_ = numel(targets_train);

    if nfeatures ~= nfeatures_ || ntrain_ ~= ntrain
        error('illegal input size');
    end

    if ~cached_has_matlabcsvm()
        cosmo_check_external('matlabcsvm');
    end

    [class_idxs, classes] = cosmo_index_unique(targets_train(:));
    nclasses = numel(classes);

    if nfeatures == 0 || nclasses == 1
        % matlab's svm cannot deal with empty data, so predict all
        % test samples as the class of the first sample
        predicted = targets_train(1) * ones(ntest, 1);
        return
    end

    opt_cell = opt2cell(opt);

    % number of pair-wise comparisons
    ncombi = nclasses * (nclasses - 1) / 2;

    % allocate space for all predictions
    all_predicted = NaN(ntest, ncombi);

    % Consider all pairwise comparisons (over classes)
    % and store the predictions in all_predicted
    pos = 0;
    for k = 1:(nclasses - 1)
        for j = (k + 1):nclasses
            pos = pos + 1;
            % classify between 2 classes only
            idxs = cat(1, class_idxs{k}, class_idxs{j});

            model = fitcsvm(samples_train(idxs, :), targets_train(idxs), ...
                            opt_cell{:});

            pred = predict(model, samples_test(idxs, :));
            all_predicted(idxs, pos) = pred;
        end
    end

    assert(pos == ncombi);

    % find the classes that were predicted most often.
    % ties are handled by cosmo_winner_indices
    [winners, test_classes] = cosmo_winner_indices(all_predicted);

    predicted = test_classes(winners);

    % helper function to convert cell to struct
function opt_cell = opt2cell(opt)

    if isempty(opt)
        opt_cell = cell(0);
        return
    end

    fns = fieldnames(opt);

    n = numel(fns);
    opt_cell = cell(1, 2 * n);
    for k = 1:n
        fn = fns{keep_id(k)};
        opt_cell{k * 2 - 1} = fn;
        opt_cell{k * 2} = opt.(fn);
    end

function tf = cached_has_matlabcsvm()
    persistent cached_tf

    if isequal(cached_tf, true)
        tf = true;
        return
    end

    cached_tf = cosmo_check_external('matlabcsvm');
    tf = cached_tf;
