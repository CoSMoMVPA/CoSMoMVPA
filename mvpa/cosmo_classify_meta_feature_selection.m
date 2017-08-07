function predicted=cosmo_classify_meta_feature_selection(samples_train, targets_train, samples_test, opt)
% meta classifier that uses feature selection on the training data
%
% predicted=cosmo_classify_meta_feature_selection(samples_train, targets_train, samples_test, opt)
%
% Inputs:
%   samples_train      PxR training data for P samples and R features.
%   targets_train      Px1 training data classes.
%   samples_test       QxR test data.
%   opt                struct with the following fields:
%      .child_classifier                  handle to classifier to use (e.g.
%                                         @cosmo_classify_matlabsvm).
%      .feature_selector                  handle to feature selector (e.g.
%                                         @cosmo_anova_feature_selector).
%      .feature_selection_ratio_to_keep   ratio of how many features to
%                                         keep. Should be in between 0 and
%                                         1.
% Output:
%   predicted          Qx1 predicted data classes for samples_test
%
% Example:
%     ds_tl=cosmo_synthetic_dataset('nchunks',5,'ntargets',5,...
%                         'type','meeg');
%     %
%     measure_args=struct();
%     measure=@cosmo_crossvalidation_measure;
%     measure_args.classifier=@cosmo_classify_meta_feature_selection;
%     measure_args.child_classifier=@cosmo_classify_lda;
%     measure_args.feature_selector=@cosmo_anova_feature_selector;
%     measure_args.feature_selection_ratio_to_keep=.6;
%     measure_args.partitions=cosmo_nchoosek_partitioner(ds_tl,1);
%     nbrhood=cosmo_interval_neighborhood(ds_tl,'time','radius',0);
%     %
%     res=cosmo_searchlight(ds_tl,nbrhood,measure,measure_args,...
%                                             'progress',false);
%     cosmo_disp(res.samples)
%     > [ 0.28      0.52 ]
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    [ntrain,nfeatures]=size(samples_train);
    [ntrain__,one__]=size(targets_train);
    nfeatures__=size(samples_test,2);

    if ntrain~=ntrain__
        error('sample count mismatch between samples and targets');
    end

    if nfeatures~=nfeatures__
        error('feature count mismatch between train and test data');
    end

    if one__~=1
        error('targets must be a column vector');
    end

    classifier=opt.child_classifier;
    feature_selector=opt.feature_selector;
    ratio_to_keep=opt.feature_selection_ratio_to_keep;

    % make a temporary dataset from the training set
    ds=struct();
    ds.samples=samples_train;
    ds.sa.targets=targets_train;
    ds.sa.chunks=(1:size(targets_train,1))'; % assume all independent
    feature_idxs=feature_selector(ds, ratio_to_keep);

    % select data with the 'best' features
    selected_samples_train=samples_train(:,feature_idxs);
    selected_samples_test=samples_test(:,feature_idxs);

    % use the classifier to predict it on that data
    predicted=classifier(selected_samples_train, targets_train, ...
                            selected_samples_test, opt);

