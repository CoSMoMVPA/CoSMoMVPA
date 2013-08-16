.. cosmo_cross_validate_skl

cosmo cross validate skl
------------------------
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
    
    if nargin<4
        opt=struct();
    end
    
    train_indices = partitions.train_indices;
    test_indices = partitions.test_indices;
    
    npartitions=numel(train_indices);
    
    [nsamples,nfeatures]=size(dataset.samples);
    
    pred=zeros(nsamples,1); % space for output
    ncorrect=0; % how many samples were correctly classified
    ntotal=0; % how many samples were classified (correctly or not)
    
    for k=1:npartitions
        %%%% >>> YOUR CODE HERE <<< %%%%
    end
    
    
    accuracy = ncorrect/ntotal;