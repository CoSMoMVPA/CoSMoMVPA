.. solution_5

For-loop for cross-validation
=============================

.. code-block:: matlab


    for k=1:npartitions
        train_data = dataset.samples(train_indices{k},:);
        test_data = dataset.samples(test_indices{k},:);
        
        train_targets = dataset.sa.targets(train_indices{k});
        
        p = args.classifier(train_data, train_targets, test_data, opt);
        pred(test_indices{k}) = p;
        
        test_targets = dataset.sa.targets(test_indices{k});
        ncorrect = ncorrect + sum(p(:) == test_targets(:));
        ntotal = ntotal + numel(test_targets);
    end
