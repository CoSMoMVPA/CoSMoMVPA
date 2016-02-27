.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. ex_rsa_tutorial

Representational similarity analysis
====================================

Visualizing dissimilarity matrices
++++++++++++++++++++++++++++++++++

Dissimilarities, based on neural data, behavioural data, and/or model data, can be visualised in various ways.

Compute the similarities in the ``ev`` and ``vt`` regions for participant ``s01`` across the six categories, and load the model similarities for the behavioural ratings. Then visualize the similarities in three ways:

- with dissimilarity matrices
- with dendograms
- with multi-dimensional scaling


Hint: :ref:`run_rsa_visualize_skl`.

Solution: :ref:`run_rsa_visualize` / :pb:`rsa_visualize`.



Comparing dissimilarity matrices
++++++++++++++++++++++++++++++++

It is easy to compare dissimilarity matrices by computing the
Pearson correlation between two flattened upper triangle DSMs using the
:ref:`cosmo_corr` function. For the next exercise, stack flattened DSMs vertically
into a single matrix starting with all of the EV DSMs from every subject then
all of the VT DSM. You should have a 10x15 matrix. Then add the v1 model and the
behavioral DSMs to make it a 12x15 matrix. Now compute the cross-correlation
matrix using :ref:`cosmo_corr`. Visualize the cross-correlation matrix with
**imagesc**. Try this with demeaning and without demeaning to compare the
results. Finally, use matlabs **boxplot** function to view the distributions of
correlations between neural simiilarities and model/behavioral DSMs.

Hint: :ref:`run_compare_dsm_skl`.

Solution: :ref:`run_compare_dsm` / :pb:`compare_dsm`.

Target dissimilarity matrix searchlight
+++++++++++++++++++++++++++++++++++++++
The function :ref:`cosmo_target_dsm_corr_measure` implements representational similarity. Use this measure to map where the neural similarity is similar to the behavioural similarity.

It is recommended to center the data using the ``center_data`` option.

Advanced exercise: the :ref:`cosmo_target_dsm_corr_measure` function can also run regression on multiple dissimilarity matrices. Use this function to estimate the contribution of the V1 and behavioural model using a searchlight.

Hint: :ref:`run_rsm_measure_searchlight_skl`

Solution: :ref:`run_rsm_measure_searchlight` / run_rsm_measure_searchlight_pb_

.. _run_rsm_measure_searchlight_pb: _static/publish/run_rmm_measure_searchlight.html

