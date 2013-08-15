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

.. literalinclude:: cosmo_nfold_partitioner_hdr.m
   :language: matlab

Hint: cosmo_nfold_partitioner_skl_

.. _cosmo_nfold_partitioner_skl: cosmo_nfold_partitioner_skl.html

Solution: cosmo_nfold_partitioner_

.. _cosmo_nfold_partitioner: cosmo_nfold_partitioner.html
