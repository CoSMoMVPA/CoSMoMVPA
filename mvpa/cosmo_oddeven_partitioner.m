function partitions = cosmo_oddeven_partitioner(ds, type)
% generates an odd-even partition scheme
%
% partitions=cosmo_oddeven_partitioner(chunks,[type])
%
% Input
%    ds              dataset struct with field .ds.chunks, or Px1 chunk
%                    indices (for P samples).
%    type            One of:
%                    - 'full': two partitions are returned, training on odd
%                       and testing on even and vice versa (default)
%                    - 'half': a single partition is returned, training on
%                       odd and testing on even only.
%
% Output:
%    partitions      A struct with fields .train_indices and .test_indices.
%                    Each of these is an Nx1 cell (for N partitions), where
%                    .train_indices{k} and .test_indices{k} contain the
%                    sample indices for the sets of unique chunks
%                    alternatingly
%
% Example:
%     ds=struct();
%     ds.sa.samples=NaN(6,99); % will be ignored by this function
%     ds.sa.chunks=[1 1 2 2 6 7 7 6]';
%     p=cosmo_oddeven_partitioner(ds);
%     % note that chunks=6 ends up in the odd chunks and chunks=7 in the
%     % even chunks, as 6 [7] is the third [fourth] unique value of chunks.
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 1    [ 3
%     >       2      4
%     >       5      6
%     >       8 ]    7 ] }
%     > .test_indices
%     >   { [ 3    [ 1
%     >       4      2
%     >       6      5
%     >       7 ]    8 ] }
%     >
%     %
%     % only half-partition (for correlation-based analysis)
%     p=cosmo_oddeven_partitioner(ds,'half');
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 1
%     >       2
%     >       5
%     >       8 ] }
%     > .test_indices
%     >   { [ 3
%     >       4
%     >       6
%     >       7 ] }
%
% Notes:
% - More generally, this function is intended as an exercise. If
%   chunks is different from 1:K for all K, then it may yield non-optimal
%   partitions.
%   Is is thus advised to use cosmo_nchoosek_partitioner(chunks,.5);
%
% See also cosmo_nchoosek_partitioner
%
% NNO Aug 2013

    chunks=get_chunks(ds);

    if nargin<2 || isempty(type)
        type='full';
    end

    switch type
        case 'full'
            do_half_partition=false;
        case 'half'
            do_half_partition=true;
        otherwise
            error('illegal type: must be ''full'' or ''half''');
    end


    indices=cosmo_index_unique(chunks);
    nparts=numel(indices);
    if nparts<2
        error('Need >=2 chunks, found %d', numel(indices));
    end

    % there are two partitions, unless do_half_partition in which case
    % there is one

    if do_half_partition && mod(nparts,2)==0
        npartitions=1;
    else
        npartitions=2;
    end

    % allocate space for output
    train_indices=cell(1,npartitions);
    test_indices=cell(1,npartitions);

    % Make partitions using even and odd chunks
    % >@@>

    % find the indices of even and odd chunks
    odd_indices=cat(1,indices{1:2:end});
    even_indices=cat(1,indices{2:2:end});

    % set the train and test indices
    train_indices{1}=odd_indices;
    test_indices{1}=even_indices;

    if npartitions==2
        train_indices{2}=even_indices;
        test_indices{2}=odd_indices;
    end

    % <@@<

    partitions.train_indices=train_indices;
    partitions.test_indices=test_indices;



function ds=get_chunks(ds)
    if isnumeric(ds) && isvector(ds)
        % direct numeric
        return
    elseif isstruct(ds)
        if cosmo_isfield(ds,'sa.chunks')
            ds=ds.sa.chunks;
            return
        end
    end

    error(['illegal input: expected dataset struct with field '...
                '.sa.chunks, or numeric vector']);


