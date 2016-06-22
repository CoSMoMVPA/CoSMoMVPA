
.. _`ex_roi_neighborhood`:

Using CoSMoMVPA *neighborhoods* for regions of interest
=======================================================

Rationale
+++++++++

A :ref:`previous exercise <ex_measures>` showed how to use a :ref:`measure <cosmomvpa_measure>` to both simplify and generalize across different common MVPA techniques (split-half correlations (:ref:`split-half correlations <ex_splithalf_correlations>` and :ref:`classification with cross-validation <ex_nfold_crossvalidation>`).

It is often useful to apply the *same measure* to *different subsets of the features*, for example:

    - Analysis of multiple ROIs.
    - Searchlight analysis, which is essentially repeated ROI analysis where each feature of the dataset is associated with a set of features around it.

CoSMoMVPA_ uses a :ref:`neighborhood <cosmomvpa_neighborhood>` to define *which* subsets of features are used.

Exercises
+++++++++

Before starting this exercise, please read the following:

    - :ref:`cosmomvpa_neighborhood`

As a preparation for a whole-brain spherical searchlight, this exercise will make a very simple neighborhood that contains indices for only two ROIs (whole-brain searchlights have thousands of (partially overlapping) regions). In each ROI classification analysis with cross-validation and split-half correlation analysisis performed.

Part 1 requires the *manual* application of a measure to features indexed by the neighborhood; Parts 2, 3 and 4 show how a :ref:`cosmo_searchlight` can be used to achieve the same.

Notes:

    - this exercise requires familiarity with the :ref:`measure <cosmomvpa_measure>` concept (:ref:`exercise <ex_measures>`).
    - understanding the concept of a neighborhood is important for :ref:`another exercise <ex_searchlight_measure>` about whole-brain :ref:`searchlights <searchlight>`.

Part 1
######

Load the dataset with subject ``s01``'s t-statistic for every run (``glm_T_stats_perrun.nii``), but do not apply a mask.
Then load each of the two masks (``vt``, ``ev``), and define a neighborhood where the ``.neighbors`` is a cell with two elements, each containing the features indices of the respective masks. Use :ref:`cosmo_slice` to slice the dataset along features (once for each mask), then apply the :ref:`cosmo_crossvalidation_measure` measure with the :ref:`cosmo_classify_lda` classifier and partitions from :ref:`cosmo_nfold_partitioner` to compute classification accuracies for each of the masks.

Part 2
######

Using the neighborhood structure defined in Part 1, use the :ref:`cosmo_searchlight` function to perform the same analysis as in Part 1.


Part 3
######

Using the same neighborhood structure, compute the split-half correlation measure (difference between Fisher-transformed on-diagonal versus off-diagonal elements) using :ref:`cosmo_correlation_measure`.

Part 4 (advanced)
#################

Use the same neighborhood and measure as in Part 2, but now let the measure return the predictions of each sample in each ROI. Run the searchlight, compute the confusion matrices, and visualize these.

Template: :ref:`run_roi_neighborhood_skl`

Check your answers here: :ref:`run_roi_neighborhood` / :pb:`roi_neighborhood`

.. include:: links.txt
