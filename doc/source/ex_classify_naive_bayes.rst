.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. ex_classify_naive_bayes

Classification with Naive Bayes classifier
==========================================

Load a dataset using subject s01's T-statistics for every run
('glm_T_stats_perrun.nii.gz') runs and the VT mask. Slice the datset using your sample
attributes slicer so that there are only two categories: monkeys and mallards.
Then slice the datasdet again into odd and even runs.  Train and test a
Naive bayes classifier (:ref:`cosmo_classify_naive_bayes`) first training on the even-runs data and testing on the
odds, then train on the odds and test on the evens.

Check your answers here: :ref:`run_classify_naive_bayes` / :pb:`classify_naive_bayes`

What is the accuracy for monkey versus ladybug? Monkey versus lemur?

Do the accuracies change if you use betas ('glm_betas_perrun.nii.gz') instead of
T-stats?

What if you use a different mask?

