.. cosmo_splithalf_partitioner_hdr

cosmo splithalf partitioner hdr
-------------------------------
.. code-block:: matlab

    function partitions = cosmo_splithalf_partitioner(chunks)
    % generates an n-fold partition scheme
    %
    % partitions=cosmo_splithalf_partitioner(chunks)
    %
    % Input
    %  - chunks          Px1 chunk indices for P samples. It can also be a
    %                    dataset with field .sa.chunks
    %
    % Output:
    %  - partitions      A struct with fields .train_indices and .test_indices.
    %                    Each of these is an 2x1 cell (for 2 partitions), where
    %                    .train_indices{k} and .test_indices{k} contain the
    %                    sample indices for the odd and even chunks
    %                    
    % Example:
    % p=cosmo_splithalf_partitioner([1 1 2 2 3 3 3])
    % > p = train_indices: {[5x1 double]  [2x1 double]}
    % >     test_indices: {[2x1 double]  [5x1 double]}
    % p.train_indices{1}'
    % >     [1 2 5 6 7]
    % p.test_indices{1}'
    % >     [3 4]
    %
    % NNO Aug 2013