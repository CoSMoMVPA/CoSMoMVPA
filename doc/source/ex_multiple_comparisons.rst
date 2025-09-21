.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`ex_multiple_comparisons`:

Using CoSMoMVPA multiple-comparison correction
==============================================

Rationale
+++++++++

A :ref:`previous exercise <ex_searchlight>` showed how to generate a whole-brain map. How do we know which features (voxels) show a significant effect?

A few approaches for whole-brain multiple-comparison methods have been proposed in the literature, but are *not* used in CoSMoMVPA:

- Bonferroni correction; typically too conservative.
- FDR: can lead to invalid inferences.
- Parametric cluster-based methods (SPM, AFNI, FSL): can be too liberal.
- Fixed-treshold cluster-based approach: requires choosing an uncorrected (feature-wise) threshold.

In CoSMoMVPA we supply an implementation for Threshold-Free Cluster Enhancement (:cite:`SN09`). Optionally this can also be used with first-level null-data (:cite:`SCT13`), although that is not done in this exercise.


Exercise with fMRI data
+++++++++++++++++++++++


Note: Since data in the ak6 dataset is not in MNI space, we cannot do group analysis. This exercise therefore considers data from one subject using data in ten chunks corresponding to ten runs.
However, the approach can also be used (in exactly the same way) for group analysis, where each chunk corresponds to one subject.

In this exercise, load data from ten runs from the ``ak6`` datasets. Compute, for each chunk, the effect of stimulus presentation versus baseline. Then, using :ref:`cosmo_cluster_neighborhood` and :ref:`cosmo_montecarlo_cluster_stat`, compute a TFCE zscore map corrected for multiple comparisons.

Extra exercise: do the same analysis for primates versus insects.

Template: :ref:`run_multiple_comparison_correction_skl`

Check your answers here: :ref:`run_multiple_comparison_correction` / :pb:`multiple_comparison_correction`


Exercise with time-generalization data
++++++++++++++++++++++++++++++++++++++
In the MEG datasets coming with CoSMoMVPA there is only data from one participant. For this exercise we split the data in ten parts and treat each as coming from one pseudo-participant.

After splitting the data in ten parts, run the time generalization measure on each part, looking for pairs of time points from which the data shows category information. After the necessary transpositions run cosmo_montecarlo_cluster_stat to obtain a group map corrected for multiple comparisons.

Template: :ref:`run_meeg_time_generalization_mcc_skl`

Check your answers here: :ref:`run_meeg_time_generalization_mcc` / :pb:`run_meeg_time_generalization_mcc`

.. include:: links.txt
