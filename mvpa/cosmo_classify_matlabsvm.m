function predicted=cosmo_classify_matlabsvm(samples_train, targets_train, samples_test, opt)
% SVM multi-classifier using matlab's SVM implementation
%
% predicted=cosmo_classify_matlabsvm(samples_train, targets_train, samples_test, opt)
%
% Inputs
%   samples_train      PxR training data for P samples and R features
%   targets_train      Px1 training data classes
%   samples_test       QxR test data
%   opt                (optional) struct with options for svm_classify
%
% Output
%   predicted          Qx1 predicted data classes for samples_test
%
% Notes:
%  - this function uses matlab's builtin svmtrain function, which has
%    the same name as LIBSVM's version. Use of this function is not
%    supported when LIBSVM's svmtrain precedes in the matlab path; in
%    that case, adjust the path or use cosmo_classify_libsvm instead.
%  - for a guide on svm classification, see
%      http://www.csie.ntu.edu.tw/~cjlin/papers/guide/guide.pdf
%    note that cosmo_crossvalidate and cosmo_crossvalidation_measure
%    provide an option 'normalization' to perform data scaling
%
% See also svmtrain, svmclassify, cosmo_classify_svm, cosmo_classify_libsvm
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<4, opt=struct(); end

    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);

    if nfeatures~=nfeatures_ || ntrain_~=ntrain,
        error('illegal input size');
    end

    classes=unique(targets_train);
    nclasses=numel(classes);

    if nclasses<2 || nfeatures==0
        % matlab's svm cannot deal with empty data, so predict all
        % test samples as the class of the first sample
        predicted=targets_train(1) * (ones(ntest,1));
        return
    end

    % number of pair-wise comparisons
    ncombi=nclasses*(nclasses-1)/2;

    % allocate space for all predictions
    all_predicted=zeros(ntest, ncombi);

    % Consider all pairwise comparisons (over classes)
    % and store the predictions in all_predicted
    pos=0;
    for k=1:(nclasses-1)
        for j=(k+1):nclasses
            pos=pos+1;
            % classify between 2 classes only (from classes(k) and classes(j)).
            % >@@>
            mask_k=targets_train==classes(k);
            mask_j=targets_train==classes(j);
            mask=mask_k | mask_j;

            pred=cosmo_classify_matlabsvm_2class(samples_train(mask,:), ...
                            targets_train(mask), samples_test, opt);
            % <@@<
            all_predicted(:,pos)=pred;
        end
    end

    % find the classes that were predicted most often.
    % ties are handled by cosmo_winner_indices
    [winners, test_classes]=cosmo_winner_indices(all_predicted);

    predicted=test_classes(winners);

