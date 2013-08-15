.. cosmo_cross_validate_hdr

cosmo cross validate hdr
========================
.. code-block:: matlab

    function [pred, accuracy] = cosmo_cross_validate(dataset, classifier, partitions, opt)
    % performs cross-validation using a classifier
    %
    % [pred, accuracy] = cosmo_cross_validate(dataset, args)
    % 
    % Inputs
    %   dataset             struct with fields .samples (PxQ for P samples and 
    %                       Q features) and .sa.targets (Px1 labels of samples)
    %   classifier          function handle to classifier, e.g.
    %                       @classify_naive_baysian
    %   partitions          For example the output from nfold_partition
    %   opt                 optional struct with options for classifier
    %   
    % 
    %
    % NNO Aug 2013 