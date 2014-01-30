function partitions = cosmo_evenodd_partitioner(chunks)
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
% cosmo_oddeven_partitioner([1 1 2 2 3 3 3])
% >    train_indices: {[3 4]  [1 2 5 6 7]}
% >    test_indices: {[1 2 5 6 7]  [3 4]}
%
% Notes: 
% - For splithalf correlation measures it is recommended to use 
%   cosmo_nchoosek_partitioner(chunks,'half'). 
% - More generally, this function is intended as an exercise. If
%   chunks is different from 1:K for all K, then it may yield non-optimal
%   partitions. 
%   Is is thus advised to use cosmo_nchoosek_partitioner(chunks,.5);
%
% See also cosmo_nchoosek_partitioner
%
% NNO Aug 2013
    
    if isstruct(chunks)
        if isfield(chunks,'sa') && isfield(chunks.sa,'chunks')
            chunks=chunks.sa.chunks;
        else
            error('illegal input')
        end
    end
    
    [classes,foo,chunk_indices]=unique(chunks);
    if numel(classes)<2
        error('Need >=2 classes, found %d', numel(classes));
    end
    
    % there are two partitions
    npartitions=2;
    
    % allocate space for output
    train_indices=cell(npartitions,1);
    test_indices=cell(npartitions,1);
    
    % Make partitions using even and odd chunks
    % >@@>
    
    % generate a mask with even indices
    even_mask=mod(chunk_indices,2)==0;
    
    % find the indices of even and odd chunks
    even_indices=find(even_mask);
    odd_indices=find(~even_mask);
    
    % set the train and test indices
    train_indices{1}=even_indices;
    train_indices{2}=odd_indices;
    
    test_indices{1}=odd_indices;
    test_indices{2}=even_indices;
    
    % <@@<
    
    partitions.train_indices=train_indices;
    partitions.test_indices=test_indices;
    
        
    