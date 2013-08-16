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

.. include:: cosmo_nfold_partitioner_hdr.rst

Hint: cosmo_nfold_partitioner_skl_

Solution: cosmo_nfold_partitioner_

Extra exercise: write a split half partitioner where there are two partitions only of approximately equal size (for example, using odd and even chunks). 

Hint: cosmo_splithalf_partitioner_hdr_

Solution: cosmo_splithalf_partitioner_

Extra advanced exercise: write a (K,N)-fold partitioner that returns all partitions for N chunks so that there are K chunks in the test set and (N-K) chunks in the training set.  

.. _cosmo_nfold_partitioner_skl: cosmo_nfold_partitioner_skl.html
.. _cosmo_nfold_partitioner: cosmo_nfold_partitioner.html

.. _cosmo_splithalf_partitioner_hdr: cosmo_splithalf_partitioner_hdr.html
.. _cosmo_splithalf_partitioner: cosmo_splithalf_partitioner.html

