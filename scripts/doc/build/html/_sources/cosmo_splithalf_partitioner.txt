.. cosmo_splithalf_partitioner

cosmo splithalf partitioner
===========================
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
    %                    Each of these is an 1x2 cell for 2 partitions, where
    %                    .train_indices{k} and .test_indices{k} contain the
    %                    sample indices for the odd and even chunks
    %                    
    % Example:
    % p=cosmo_nfold_partitioner([1 1 2 2 3 3 3])
    % > p = train_indices: {[5x1 double]  [2x1 double]}
    % >     test_indices: {[2x1 double]  [5x1 double]}
    % p.train_indices{1}'
    % >     [1 2 5 6 7]
    % p.test_indices{1}'
    % >     [3 4]
    %
    % NNO Aug 2013
    
    if isstruct(chunks)
        if isfield(chunks,'sa') && isfield(chunks.sa,'chunks')
            chunks=chunks.sa.chunks;
        else
            error('illegal input')
        end
    end
    
    unq=unique(chunks);
    nchunks=2;
    
    % allocate space for output
    train_indices=cell(1,nchunks);
    test_indices=cell(1,nchunks);
    
    % Make partitions using even and odd chunks
    for k=1:nchunks
        test_msk=mod(chunks,2)==k-1;
        train_indices{k}=find(~test_msk)';
        test_indices{k}=find(test_msk)';
    end
    
    partitions.train_indices=train_indices;
    partitions.test_indices=test_indices;
    
        
    