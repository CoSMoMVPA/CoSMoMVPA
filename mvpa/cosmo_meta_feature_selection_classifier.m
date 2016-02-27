function predicted=cosmo_meta_feature_selection_classifier(samples_train, targets_train, samples_test, opt)
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
% Notes:
%   - this function is deprecated. Use
%     cosmo_classify_meta_feature_selection instead.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

cosmo_warning(['%s is deprecated and will be removed in the future; '...
                'use cosmo_classify_meta_feature_selection instead'],...
                mfilename());

predicted=cosmo_classify_meta_feature_selection(samples_train, ...
                                    targets_train, samples_test, opt);
