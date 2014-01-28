.. ex_searchlight_measure

Use the searchlight with a classifier and a cross-validation measure
====================================================================

In this exercise we bring the generic :ref:`cosmo_crossvalidation_measure` and :ref:`cosmo_searchlight` functions together, by applying the measure to each searchlight location.

With the help of these functions, run n-fold cross validation and use a nearest neighbor classifier to compute accuracy maps. Visualize the output map and show a histogram of the classification accuracies.

.. include:: matlab/cosmo_searchlight_skl.txt

Hint: :ref:`run_measure_searchlight_skl`

Solution: :ref:`run_measure_searchlight` / :pb:`measure_searchlight`
