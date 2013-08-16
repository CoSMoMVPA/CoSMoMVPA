.. cosmo_cross_validation_measure_hdr

cosmo cross validation measure hdr
==================================
.. code-block:: matlab

    function accuracy = cosmo_cross_validation_measure(dataset, args)
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
    % ACC. Modified to conform to signature of generic datset 'measure'
    % NNO made this a wrapper function