.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. ex_nfold_partitioner

Cross-validation part 1: N-Fold Partitioner
===========================================

Before we can do cross validation, we need to partition the data into different
sets of training and testing folds. In the standard leave-one-run-out
cross-validation scheme we make N-partitions (for N-runs) where each run takes
turns being the testing data, while the classifier is trained on all the other
runs. This means that for every data fold we need a set of sample indices for
training and another for testing. Below is a an incomplete function that computes the
partitions for a given set of chunks sample attributes.  Your task is to
complete the function by writing the missing for-loop.

.. include:: matlab/cosmo_nfold_partitioner_hdr.txt

Hint: :ref:`cosmo_nfold_partitioner_skl`

Solution: :ref:`cosmo_nfold_partitioner`

Extra exercise: write a split half partitioner where there are two partitions only of approximately equal size (for example, using odd and even chunks).

Hint: :ref:`cosmo_oddeven_partitioner_hdr`

Solution: :ref:`cosmo_oddeven_partitioner`

Extra advanced exercise: write a (K,N)-fold partitioner that returns all partitions for N chunks so that there are K chunks in the test set and (N-K) chunks in the training set.

