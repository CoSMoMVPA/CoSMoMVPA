.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`ex_measures`:

Using CoSMoMVPA *measures*
==========================

Rationale
+++++++++

Previous exercises discussed how to compute both split-half correlations (:ref:`ex_splithalf_correlations`) and classification accuracies using cross-validation (:ref:`ex_nfold_crossvalidation`). Both types of analysis share a common input and output pattern:

    - The input is a dataset struct (with at least ``.sa.chunks`` and ``.sa.targets`` properly set)
    - The output consists of one or more values, which can be stored into a new output dataset
    - Optionally, there may be some miscellaneous options that specify specifics on the operations.

        + for split-half correlations, these could be how to normalize the correlations (the default is a Fisher-transform using the ``atanh`` function)
        + for cross-validation, these are the partitioning scheme for cross-validation (e.g. odd-even or n-fold) and the classifier (e.g. LDA, SVM, or Naive Bayes) to use.

This pattern is captured by the CoSMoMVPA dataset :ref:`measure <cosmomvpa_measure>` concept. An important reason for using measures is that it allows for a flexible implementation of :ref:`searchlights <searchlight>`, which involve the repeated application of the same measure to subsets of features.

The measure concept
+++++++++++++++++++
A dataset measure is a function with the following signature:

    .. code-block:: matlab

        output = dataset_measure(dataset, args)

where:

    - ``dataset`` is a dataset struct.
    - ``args`` are options specific for that measure.
    - ``output`` must be a ``struct`` with fields ``.samples`` (in column vector format) and optionally a field ``.sa``

        + it should not have fields ``.fa``.
        + usually it has no field ``.a`` (except for some complicated cases where it can have an ``.a.sdim`` field, if the measure returns data in a dimensional format).


Split-half correlations using a measure
+++++++++++++++++++++++++++++++++++++++
Before starting this exercise, please make sure you have read about:

- :ref:`matlab_octave_function_handles`
- :ref:`cosmomvpa_measure`

As a first exercise, load two datasets using subject ``s01``'s T-statistics for odd and even runs
(``glm_T_stats_even.nii`` and ``glm_T_stats_odd.nii``) and the VT mask.
Assign targets and chunks, then join the two datasets using ``cosmo_stack``. Then use :ref:`cosmo_correlation_measure` to:

    - compute the correlation information (Fisher-transformed average of no-diagonal versus off-diagonal elements).
    - the raw correlation matrix.

Then compute the correlation information for each subject, and perform a t-test against zero over subjects.

Template: :ref:`run_correlation_measure_skl`

Check your answers here: :ref:`run_correlation_measure` / :pb:`correlation_measure`

.. _`ex_measures_crossvalidation`:

Classifier with cross-validation using a measure
++++++++++++++++++++++++++++++++++++++++++++++++
As a second exercise, load a dataset using subject ``s01``'s T-statistics for every run
(``glm_T_stats_perrun.nii``) and the VT mask.

Assign targets and chunks, then use the LDA classifier (:ref:`cosmo_classify_lda`) and n-fold partitioning (:ref:`cosmo_nfold_partitioner`) to compute classification accuracy using n-fold cross-validation, using :ref:`cosmo_crossvalidation_measure`.

Then compute confusion matrices using different classifiers, such as :ref:`cosmo_classify_lda`, :ref:`cosmo_classify_nn`, and :ref:`cosmo_classify_naive_bayes`. If LIBSVM or the `Matlab statistics` toolbox are available, you can also use :ref:`cosmo_classify_svm`.

Template: :ref:`run_crossvalidation_measure_skl`

Check your answers here: :ref:`run_crossvalidation_measure` / :pb:`crossvalidation_measure`

.. include:: links.txt

