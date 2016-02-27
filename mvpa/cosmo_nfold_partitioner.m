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
%     % simple partitioning scheme with 3 chunks with two samples each
%     % (chunk values are not necessarily in increasing order)
%     p=cosmo_nfold_partitioner([3 1 2 3 2 1]);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 1    [ 1    [ 2
%     >       3      2      3
%     >       4      4      5
%     >       5 ]    6 ]    6 ] }
%     > .test_indices
%     >   { [ 2    [ 3    [ 1
%     >       6 ]    5 ]    4 ] }
%
%     % show the same with a dataset struct
%     ds=struct();
%     ds.samples=randn(6,99); % 6 samples, 99 features
%     ds.sa.targets=[1 2 1 2 1 2]'; % conditions; ignored by this function
%     ds.sa.chunks=[3 1 2 3 2 1]';  % used for partitioning
%     p=cosmo_nfold_partitioner(ds);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 1    [ 1    [ 2
%     >       3      2      3
%     >       4      4      5
%     >       5 ]    6 ]    6 ] }
%     > .test_indices
%     >   { [ 2    [ 3    [ 1
%     >       6 ]    5 ]    4 ] }
%
%
%     % Example of an unbalanced partitioning scheme. Generally it is
%     % advised to balance the partitions before using them for MVPA.
%     % (see cosmo_balance_partitions)
%     ds=struct();
%     ds.samples=randn(7,99); % 7 samples (1 extra), 99 features
%     ds.sa.targets=[1 2 1 2 1 2 2]';
%     ds.sa.chunks= [1 1 3 3 3 3 3]';
%     p=cosmo_nfold_partitioner(ds);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 3    [ 1
%     >       4      2 ]
%     >       5
%     >       6
%     >       7 ]        }
%     > .test_indices
%     >   { [ 1    [ 3
%     >       2 ]    4
%     >              5
%     >              6
%     >              7 ] }
%
%
% Note:
%  - for cross-validation it is recommended to balance partitions using
%    cosmo_balance_partitions.
%  - More advanced partitining is provided by cosmo_nchoosek_partitioner.
%
% See also: cosmo_balance_partitions, cosmo_nchoosek_partitioner
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if isstruct(chunks)
        if cosmo_isfield(chunks,'sa.chunks',true)
            chunks=chunks.sa.chunks;
        end
    end

    unq=unique(chunks);
    nchunks=numel(unq);

    % allocate space for output
    train_indices=cell(1,nchunks);
    test_indices=cell(1,nchunks);

    % set the training and test indices for each chunk
    for k=1:nchunks
        % >@@>
        test_msk=unq(k)==chunks(:); % ensure column vector
        train_indices{k}=find(~test_msk);
        test_indices{k}=find(test_msk);
        % <@@<
    end

    partitions.train_indices=train_indices;
    partitions.test_indices=test_indices;



