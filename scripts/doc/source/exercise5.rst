.. exercise5

Exercise 5. Cross-validation part 2
===================================

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

.. code-block:: matlab

    function accuracy = cosmo_cross_validate(dataset, args)
    % performs cross-validation using a classifier
    %
    % accuracy = cosmo_cross_validate(dataset, args)
    % 
    % Inputs
    %   dataset             struct with fields .samples (PxQ for P samples and 
    %                       Q features) and .sa.targets (Px1 labels of samples)
    %   args                struct containing classifier, partitions, and opt (which
    %                           is optional)
    %   args.classifier     function handle to classifier, e.g.
    %                       @classify_naive_baysian
    %   args.partitions          For example the output from nfold_partition
    %   
    % NNO Aug 2013, 
    % modified by ACC. Modified to conform to signature of generic datset 'measure'

    if ~isfield(args,'opt') args.opt = struct(); end
    if ~isfield(args,'classifier') error('Missing input args.classifier'); end
    if ~isfield(args,'partitions') error('Missing input args.partitions'); end


    train_indices = args.partitions.train_indices;
    test_indices = args.partitions.test_indices;

    npartitions=numel(train_indices);

    [nsamples,nfeatures]=size(dataset.samples);

    pred=zeros(nsamples,1); % space for output
    ncorrect=0; % how many samples were correctly classified
    ntotal=0; % how many samples were classified (correctly or not)

    % >>
    
    %%% Fill in the missing code.

    % <<

    accuracy = ncorrect/ntotal;

Solution_5_

.. _Solution_5: solution_5.html
