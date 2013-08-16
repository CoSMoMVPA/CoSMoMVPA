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

Hint: cosmo_classify_nn_skl_

.. _cosmo_classify_nn_skl: cosmo_classify_nn_skl.html

Full solution: cosmo_classify_nn_

Extra exercise: write a nearest-mean classifier

Advanced exercise: write a k-nearest neighbor classifier that considers the nearest k neighbors for each test sample. Bonus points if this classifier takes a random class in case of a tie.

.. _cosmo_classify_nn: cosmo_classify_nn.html
