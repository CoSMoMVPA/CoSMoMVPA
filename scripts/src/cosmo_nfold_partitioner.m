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
for k=1:nchunks
    test_msk=unq(k)==chunks;
    train_indices{k}=find(~test_msk)';
    test_indices{k}=find(test_msk)';
end
% <<

partitions.train_indices=train_indices;
partitions.test_indices=test_indices;

    
