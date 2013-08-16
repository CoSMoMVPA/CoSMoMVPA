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

% Make partitions using even and odd chunks
% >>

nsamples=numel(targets);
halfmask=false(nsamples,1);
for k=1:2:nchunks
    halfmask=halfmask | chunks==unq(k);
end

half1=find(halfmask)

train_indices{1}=find(half_mask);

for k=1:nchunks
    msk=chunks==unq(k);
    kmod2=mod(k,2)+1;
    if kmod2==1
        train_indices{kmod2}=[train_indices{k};find(msk)'];
    else
        test_indices{kmod2}=[test_indices{k};find(msk)'];
    end
end
% <<

partitions.train_indices=train_indices;
partitions.test_indices=test_indices;

    
