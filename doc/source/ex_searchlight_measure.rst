.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`ex_searchlight_measure`:

Use the searchlight with a neighborhood and a measure
=====================================================

'I love it when a plan comes together'
++++++++++++++++++++++++++++++++++++++

In this exercise we integrate concepts and techniques described during previous exercises:

    - the generic :ref:`measure <cosmomvpa_measure>` concept (:ref:`exercise <ex_measures>`), in particular

        + :ref:`cosmo_correlation_measure`, simplifying the :ref:`split-half correlation exercise <ex_splithalf_correlations>`.

        + :ref:`cosmo_crossvalidation_measure`, simplifying the :ref:`single fold classification exercise <ex_classify_lda>` and :ref:`cross validation classification exercise <ex_nfold_crossvalidation>`.

    - the generic :ref:`neighborhood <cosmomvpa_neighborhood>` concept (:ref:`exercise <ex_roi_neighborhood>`).

to compute a whole brain *information map* using a :ref:`searchlight` that indicates where in the brain, locally, regions contain information about the conditions of interest (``.sa.targets``).

Part 1
++++++

Using :ref:`cosmo_fmri_dataset`, load the t stats for 'odd' and 'even' runs for s01 (``glm_T_stats_odd.nii`` and ``glm_T_stats_even.nii``), while supplying the ``brain`` mask. Assign chunks and targets and stack the two halves into a single dataset ``ds``.

Using :ref:`cosmo_spherical_neighborhood`, define a spherical neighborhood with a radius of 3 voxels for each feature (voxel) in ``ds``. Show a histogram of the number of features (voxels) in each element in the neighborhood.

Then, using  :ref:`cosmo_correlation_measure` and the :ref:`cosmo_searchlight` function, compute a whole-brain information map, visualize the result using :ref:`cosmo_slice`, and store the result as a NIFTI file using :ref:`cosmo_map2fmri`. The NIFTI file can be visualized with any fMRI analysis package; one simple program is MRIcron_.

Hint: :ref:`run_splithalf_correlations_searchlight_skl`

Solution: :ref:`run_splithalf_correlations_searchlight` / :pb:`splithalf_correlations_searchlight`

Part 2
++++++

Load the dataset with subject ``s01``'s t-statistic for every run (``glm_T_stats_perrun.nii``) using the ``brain`` mask and assign chunks and targets.

Using :ref:`cosmo_spherical_neighborhood`, define a spherical neighborhood with at least 100 voxels for each feature (voxel) in ``ds``.

Use :ref:`cosmo_oddeven_partitioner` to define a cross-validation scheme, and use :ref:`cosmo_crossvalidation_measure` and the :ref:`cosmo_searchlight` function to compute a whole-brain information map with classification accuracies, visualize the result using :ref:`cosmo_slice`, and store the result as a NIFTI file using :ref:`cosmo_map2fmri`.

Hint: :ref:`run_crossvalidation_searchlight_skl`

Solution: :ref:`run_crossvalidation_searchlight` / :pb:`crossvalidation_searchlight`

.. include:: links.txt

