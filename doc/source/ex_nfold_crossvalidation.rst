.. _`ex_nfold_crossvalidation`:

n-fold cross-validation
=======================

Background
++++++++++

In the :ref:`ex_classify_lda` exercise, data was split in even and odd runs, and a classifier trained and tested on these (respectively). In this exercise the use of cross-validation is shown using a dataset with ``N=10`` chunks.

    - data in a single chunk (here, the first run) is used as the test set
    - all other data is used for the train set. 
    - the previous two steps are repeated for each of the ``N=10`` chunks:

        + for the ``i``-th repetion, the ``i``-th chunk is used for testing after training on all other chunks
        + this gives a prediction for each sample in the dataset
        + classification accuracy is, as before, computed by dividing the number of correct predictions by the total number of predictions

Compared to odd-even classification demonstrated  :ref:`earlier <ex_classify_lda>`:

     + for every classification step there is a larger training set, which generally means better signal-to-noise, leading to better estimates of the training parameters, and thus better classification.
     + because a prediction is obtained for each sample in the dataset, more predictions are used to estimate classification accuracy, which leads to a better estimate of the true pattern discrimination.

Single subject, n-fold cross-validation classification
++++++++++++++++++++++++++++++++++++++++++++++++++++++

For this exercise, load a dataset using subject ``s01``'s T-statistics for every run
('glm_T_stats_perrun.nii') and the VT mask. 

- Implement ``n-fold`` crossvalidation as described above, using the :ref:`LDA classifier <cosmo_classify_lda>`.
- Compute classification accuracy
- Show a confusion matrix

Template: :ref:`run_nfold_crossvalidate_skl`

Check your answers here: :ref:`run_nfold_crossvalidate_lda` / :pb:`nfold_crossvalidate`

