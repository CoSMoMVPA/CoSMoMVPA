.. ex_classify_naive_bayes

Classification with Naive Bayes classifier
==========================================

Load a dataset using subject s01's T-statistics for every run
('glm_T_stats_perrun.nii.gz') runs and the VT mask. Slice the datset using your sample
attributes slicer so that there are only two categories: monkeys and mallards.
Then slice the datasdet again into odd and even runs.  Train and test a
Naive bayes classifier (cosmo_classify_naive_bayes_) first training on the even-runs data and testing on the
odds, then train on the odds and test on the evens.

Check your answers here: run_classify_naive_bayes_ / run_classify_naive_bayes_pb_

What is the accuracy for monkey versus ladybug? Monkey versus lemur?

Do the accuracies change if you use betas ('glm_betas_perrun.nii.gz') instead of
T-stats?

What if you use a different mask?

.. _run_classify_naive_bayes: run_classify_naive_bayes.html

.. _cosmo_classify_naive_bayes: cosmo_classify_naive_bayes.html
.. _run_classify_naive_bayes_pb: _static/publish/run_classify_naive_bayes.html



       
