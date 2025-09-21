.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. ex_write_classify_nn

Write your own Nearest-neighbor classifier
==========================================

We have begun to write a nearest neighbor classifier, but we have left out the
best part. Write the for loop that iterates over every sample in the testing
data and assigns a single label from the training targets to each of the test
samples based on which is nearest (where 'nearest', for now, is defined based on Euclidian distance). Test your classifers on pairwise or multi-class datasets.

Your function should have the following signature:

.. include:: matlab/cosmo_classify_nn_hdr.txt

Hint: :ref:`cosmo_classify_nn_skl`

Full solution: :ref:`cosmo_classify_nn`

Extra exercise: write a nearest-mean classifier.

Extra exercise: Try correlation instead of Euclidian distance.

Advanced exercise: write a k-nearest neighbor classifier that considers the nearest k neighbors for each test sample. Bonus points if this classifier uses :ref:`cosmo_winner_indices` in case of a tie. (solution: :ref:`cosmo_classify_knn`).




:pb:`classify_naive_bayes`

