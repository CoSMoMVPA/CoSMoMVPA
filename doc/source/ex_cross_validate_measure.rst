.. ex_cross_validate_measure

Cross-validation part 3: using a dataset measure
================================================

Here we introduce what we refer to as a "dataset measure". A dataset measure
is a function with the following signature: 

.. code-block:: matlab

    output = dataset_measure(dataset, args)

Thus any function you write can be used as a dataset measure as long as it can
use this input scheme. In a similar way, our classifiers all have the same
signature:

.. code-block:: matlab

     predictions = classifier(train_data, train_targets, test_data, opt)

This is useful for writing code that can be reused for different purposes. The
cross-validation dataset measure function is written to work with any generic
classifier, and returns the classification accuracy. 
This is done by passing a function handle to a classifer in the args struct
input. For example, the function handle for the nearest neighbor classifer can
be passed by the args struct by using the @function syntax:

.. code-block:: matlab
    
    args.classifier = @cosmo_classify_nn

In the code for cross validation below, your job is to write the missing for
loop. This for loop must iterate over each data fold in args.partitions, call a
generic classifier, and keep track of the number of correct classifications.

.. include:: matlab/cosmo_cross_validation_accuracy_measure_sgn.txt

Hint: :ref:`cosmo_cross_validation_accuracy_measure_skl`

Solution: :ref:`cosmo_cross_validation_accuracy_measure`

