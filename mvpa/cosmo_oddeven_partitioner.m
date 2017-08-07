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
%                       unique chunks and testing on even unique chunks,
%                       and vice versa (default). A typical use case is
%                       classification analysis (using
%                       cosmo_crossvalidation_measure)
%                    - 'half': a single partition is returned, training on
%                       odd unique chunks and testing on even unique chunks
%                       only. A typical use case is split-half
%                       correlation analysis (using
%                       cosmo_correlation_measure) because correlations are
%                       symmetric (i.e. corr(a,b)==corr(b,a) for column
%                       vectors a and b)
%
% Output:
%    partitions      A struct with fields .train_indices and .test_indices.
%                    Each of these is an Nx1 cell (N=1 when type='half',
%                    N=2 when type='full'.).
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
%   - typically, the 'half' option can be used with
%     cosmo_correlation_measure, because correlations are symmetric; the
%     'full' option can be used with cosmo_crossvalidation_measure.
%   - this function returns partitions based on the sorted unique values
%     in chunks, not the chunk values themselves. For example, if the
%     sorted unique values of .sa.chunks are [2,4,5,8], then the values
%     2 and 5 are at the 'odd' position (1 and 3), and 4 and 8 are at the
%     'even' position.
%
% See also: cosmo_nchoosek_partitioner
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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

    if do_half_partition
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


