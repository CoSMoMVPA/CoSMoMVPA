.. ex_write_classify_nn

Write your own Nearest-neighbor classifier
==========================================

We have begun to write a nearest neighbor classifier, but we have left out the
best part. Write the for loop that iterates over every sample in the testing
data and assigns a single label from the training targets to each of the test
samples. First use Eucliden distance as a measure of distance, then try
correlation distance.  Test your classifers on pairwise or multi-class datasets.

.. literalinclude:: cosmo_classify_nn_hdr.m
    :language: matlab

Skeleton_

.. _Skeleton: cosmo_classify_nn_skl.html

Full solution: here_

.. _here: cosmo_classify_nn.html
