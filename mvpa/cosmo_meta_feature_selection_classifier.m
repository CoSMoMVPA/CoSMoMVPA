function predicted=cosmo_meta_feature_selection_classifier(samples_train, targets_train, samples_test, opt)
% meta classifier that uses feature selection on the training data
%
% predicted=cosmo_meta_feature_selection_classifier(samples_train, targets_train, samples_test, opt)
%
% Inputs:
%   samples_train      PxR training data for P samples and R features.
%   targets_train      Px1 training data classes.
%   samples_test       QxR test data.
%   opt                struct with the following fields:
%      .child_classifier                  handle to classifier to use (e.g.
%                                         @cosmo_classify_svm).
%      .feature_selector                  handle to featur selector (e.g.
%                                         @cosmo_anove_feature_selector).
%      .feature_selection_ratio_to_keep   ratio of how many features to
%                                         keep. Should be in between 0 and
%                                         1.
% Output
%   predicted          Qx1 predicted data classes for samples_test
%
% NNO Aug 2013

    classifier=opt.child_classifier;
    feature_selector=opt.feature_selector;
    ratio_to_keep=opt.feature_selection_ratio_to_keep;

    % make a temporary dataset from the training set
    ds=struct();
    ds.samples=samples_train;
    ds.sa.targets=targets_train;
    feature_idxs=feature_selector(ds, ratio_to_keep);

    % select data with the 'best' features
    selected_samples_train=samples_train(:,feature_idxs);
    selected_samples_test=samples_test(:,feature_idxs);

    % use the classifier to predict it on that data
    predicted=classifier(selected_samples_train, targets_train, selected_samples_test, opt);








