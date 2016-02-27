.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. ex_crossvalidate

Cross-validation part 2: using multiple classifiers
===================================================

Using the cross-validation just implemented in ex_nfold_partitioner_, run cross validation on our favourite dataset (s01 with t-stats per run). Run this with three classifiers: SVM, neareast neighbor, and naive bayesian, and print the classification accuracies.

As an additional exercise, implement cosmo_confusion_matrix and show the confusion between predicted and actual classes and show the confusion matrix for each classifier.

Hint: run_cross_validation_skl_

Solution: run_cross_validation_ / run_cross_validation_pb_

.. _ex_nfold_partitioner: ex_nfold_partitioner.html
.. _run_cross_validation_skl: run_cross_validation_skl.html
.. _run_cross_validation: run_cross_validation.html
.. _run_cross_validation_pb: _static/publish/run_cross_validation.html
.. _ex_nfold_partitioner: ex_nfold_partitioner.html
