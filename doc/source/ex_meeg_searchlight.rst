.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`ex_meeg_searchlight`:

MEEG Searchlights
=================

This exercise requires a separate dataset named `meg-obj6`; see download_ section.
It also requires a working installation of FieldTrip_.


Part 1: MEEG univariate contrast
++++++++++++++++++++++++++++++++
Load the MEEG obj6 data for subject `s00`. Read the README file to understand how the data is represented.
Use :ref:`cosmo_meeg_dataset` to convert the dataset to a CoSMoMVPA dataset structure. How many sensors, time points and trials are in this dataset? Then compute, for each time point and sensor, the difference between face and scene stimuli. Visualize the results in FieldTrip for the magnetometers.

Part 2: MEEG time-course searchlight with classifier and cross-validation
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Using the same data as above, define a `time` neighborhood for magnetometer sensors in the posterior part of the brain.
Then, for each time point, compute use a classifier with cross-validation discriminating the six categories using data for the selected sensors, and plot a classification accuracy time course.

Part 2: MEEG time-course searchlight with split-half correlation measure
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Using the same data as above, define `chan` (channel) and `time` neighborhoods; then cross these neighborhood for a *space-time* `chan`-by-`time` neighborhood. Using :ref:`cosmo_correlation_measure`, compute split-half correlation differences for each combination of

As a second exercise, load a dataset using subject ``s01``'s T-statistics for every run
(``glm_T_stats_perrun.nii``) and the VT mask.

Assign targets and chunks, then use the LDA classifier (:ref:`cosmo_classify_lda`) and n-fold partitioning (:ref:`cosmo_nfold_partitioner`) to compute classification accuracy using n-fold cross-validation, using :ref:`cosmo_crossvalidation_measure`.

Then compute confusion matrices using different classifiers, such as :ref:`cosmo_classify_lda`, :ref:`cosmo_classify_nn`, and :ref:`cosmo_classify_naive_bayes`. If LIBSVM or the `Matlab statistics` toolbox are available, you can also use :ref:`cosmo_classify_svm`.

Hint: :ref:`run_meeg_timelock_measures_skl`

Solution: :ref:`run_meeg_timelock_measures_skl` / :pb:`meeg_timelock_measures`

.. include:: links.txt

