.. ex_cross_validate

Cross-validation part 2
=======================

This function is what we refer to as a "dataset measure". A dataset measure
is a function with the following signature: 

.. code-block:: matlab

    output = dataset_measure(dataset, args)

Thus any function you write can be used as a dataset measure as long as it can
use this same input scheme. In a similar way, our classifiers all have the same
signature:

.. code-block:: matlab

     predictions = classifier(train_data, train_targets, test_data, opt)

This is useful for writing code that can be reused for different purposes. The
cross-validation dataset measure function is written to work with any generic
classifer. This is done by passing a function handle to a classifer in the args struct
input. For example, the function handle for the nearest neighbor classifer can
be passed by the args struct by using the @function syntax:

.. code-block:: matlab
    
    args.classifier = @cosmo_classify_nn

In the code for cross validation below, your job is to write the missing for
loop. This for loop must iterate over each data fold in args.partitions, call a
generic classifier, and keep track of the number of correct classifications.

.. literalinclude:: cosmo_cross_validate_hdr.m
   :language: matlab

Hint: cosmo_cross_validate_skl_

.. _cosmo_cross_validate_skl: cosmo_cross_validate_skl.html

Solution: cosmo_cross_validate_

.. _cosmo_cross_validate: cosmo_cross_validate.html
