.. cosmo_nfold_partitioner_hdr

cosmo nfold partitioner hdr
===========================
.. code-block:: matlab

    function partitions = cosmo_nfold_partitioner(chunks)
    % generates an n-fold partition scheme
    %
    % partitions=cosmo_nfold_partitioner(chunks)
    %
    % Input
    %  - chunks          Px1 chunk indices for P samples. It can also be a
    %                    dataset with field .sa.chunks
    %
    % Output:
    %  - partitions      A struct with fields .train_indices and .test_indices.
    %                    Each of these is an 1xQ cell for Q partitions, where
    %                    .train_indices{k} and .test_indices{k} contain the
    %                    sample indices for the k-th fold.
    %                    
    % Example:
    % p=cosmo_nfold_partitioner([1 1 2 2 3 3 3])
    % > p = train_indices: {1x3 cell}
    % >     test_indices: {1x3 cell}  
    % p.train_indices{1}'
    % >     [3 4 5 6 7]
    % p.test_indices{1}
    % >     [1 2]
    %
    % NNO Aug 2013