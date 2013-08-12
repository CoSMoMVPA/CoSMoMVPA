.. exercise4

Exercise 4. Cross-validation part 1: N-Fold Partitioner
=======================================================

Before we can do cross validation, we need to partition the data into different
sets of training and testing folds. In the standard leave-one-run-out
cross-validation scheme we make N-partitions (for N-runs) where each run takes
turns being the testing data, while the classifier is trained on all the other
runs. This means that for every data fold we need a set of sample indices for
training and another for testing. Below is a an incomplete function that computes the
partitions for a given set of chunks sample attributes.  Your task is to
complete the function by writing the missing for-loop.

.. code-block:: matlab

    function partitions=cosmo_nfold_partition(chunks)
    % generates an n-fold partition scheme
    %
    % partitions=cosmo_nfold_partition(chunks)
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
    % p=cosmo_nfold_partition([1 1 2 2 3 3 3])
    % > p = train_indices: {1x3 cell}
    % >     test_indices: {1x3 cell}  
    % p.train_indices{1}'
    % >     [3 4 5 6 7]
    % p.test_indices{1}
    % >     [1 2]
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
    nchunks=numel(unq);

    % allocate space for output
    train_indices=cell(1,nchunks);
    test_indices=cell(1,nchunks);

    % >>

    %%%% Please supply the missing For-loop!!

    % <<

    partitions.train_indices=train_indices;
    partitions.test_indices=test_indices;

Solution_4_

.. _Solution_4: solution_4.html
