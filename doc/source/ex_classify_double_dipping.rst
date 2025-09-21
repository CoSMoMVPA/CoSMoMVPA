.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`ex_classify_double_dipping`:

Double dipping
==============

Background
++++++++++
In the :ref:`previous exercise <ex_classify_lda>` we noted that the train and test set must come from independent data; in the fMRI example, that meant from different runs.
In this exercise we will illustrate why this independence is so important.

The case where train and test data is not independent is a *bad thing* and should really be avoided for any type of analysis (except for illustration cases such as this exercise). It is known by various labels, including *circular analysis* and *double dipping*.


Double dipping illustration
+++++++++++++++++++++++++++
For simplicity, in this exercise we will not use the CoSMoMVPA dataset structure but use matrices and vectors directly.

In this exercise, the goal is to generate data that has absolutely no information that allows it to distinguish between two conditions. To do so, generate a training dataset with 2 classes, 20 observations each, and 10 features, with all data random from a standard normal distribution. Compute classification accuracies in two ways:

- the double dipping (circular) approach (*bad*): use the same data for training as for testing
- the independent approach (*good*): generate a new test dataset with random data of the same size as the training data.

Repeat the process 1000 times, and plot a histogram of the classification accuracies. Since in this case there were two classes and the training set was balanced, we would expect around 50 percent classification accuracy (with some variability) for the data used here. What do you see for the accuracies, both for the double dipping and independent case?

Template: :ref:`run_bad_double_dipping_analysis_skl`

Check your answers here: :ref:`run_bad_double_dipping_analysis` / :pb:`bad_double_dipping_analysis`



