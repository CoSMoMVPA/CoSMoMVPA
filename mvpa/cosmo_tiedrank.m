function ranks=cosmo_tiedrank(data, dim)
% Compute ranks for the input along the specified dimension
%
% ranks=cosmo_tiedrank(data[, dim])
%
% Inputs:
%   data                        numeric N-dimensional array
%   dim                         optional dimension along which the ranks
%                               are computed (default: 1)
%
% Output:
%   ranks                       numeric N-dimensional array with the same
%                               size as the input containing the rank of
%                               each vector along the dim-th dimension.
%                               Equal values have the same rank, which is
%                               the average of the rank the values would
%                               have if they differed by a minimal amount.
%                               NaN values in the input result in a NaN
%                               values in the output at the corresponding
%                               locations.
%                               If dim is greater than the number of
%                               dimensions in data, then all values in rank
%                               are one (or NaN of the corresponding value
%                               in data is NaN).
%
% Examples:
%     cosmo_tiedrank([1 2 2],2)
%     %|| [ 1 2.5 2.5]
%
%     cosmo_tiedrank([NaN 2 2;3 NaN 4],1)
%     %|| [ NaN     1     1;
%     %||     1   NaN     2];
%
%     cosmo_tiedrank([NaN 2 2;3 NaN 4],2)
%     %|| [ NaN   1.5   1.5;
%     %||     1   NaN     2];
%
%     cosmo_tiedrank([2 4 3 3 3 3 5 5 5],2)
%     %|| [ 1.0 6.0 3.5 3.5 3.5 3.5 8.0 8.0 8.0 ]
%
% Notes:
% - Unlike the Matlab builtin function 'tiedrank' (part of the statistics
%   toolbox), the meaning of the second argument is the dimension along
%   which the ranks are computed.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2
        dim=1;
    end

    check_inputs(data, dim);
    orig_size=size(data);

    if numel(orig_size)<dim
        % if the input data does not have enough data, then the output
        % consists of an array with only ones (or NaNs, if present)
        ranks=singleton_ranks(data);
        return;
    end

    [values,idx]=sort(data,dim);

    data_is_vector=numel(orig_size)<=2 && orig_size(3-dim)==1;
    if data_is_vector
        ranks=vector_tied_rank(values(:), idx(:));
        if orig_size(1)==1
            % transpose to turn it back into a row vector
            ranks=ranks';
        end
        return
    end


    % make the dim-th dimension the first dimension
    values_sh=shiftdim(values,dim-1);
    idx_sh=shiftdim(idx,dim-1);
    sh_size=size(values_sh);

    count_along_dim=size(values_sh,1);

    % reshape into a matrix
    values_mat=reshape(values_sh,count_along_dim,[]);
    idx_mat=reshape(idx_sh,count_along_dim,[]);

    % space for output
    ranks_mat=zeros(size(idx_mat));

    % compute for each column vector
    n_col=size(ranks_mat,2);
    for k=1:n_col
        ranks_mat(:,k)=vector_tied_rank(values_mat(:,k),idx_mat(:,k));
    end

    % put back in shape after shiftdim
    ranks_sh=reshape(ranks_mat,sh_size);

    % undo shiftdim
    unshift_count=numel(orig_size)-dim+1;
    ranks=reshape(shiftdim(ranks_sh,unshift_count),orig_size);



function ranks=vector_tied_rank(sorted_values, sort_idx)
% sorted_values and sort_idx are the output from 'sort'
% it is assumes that sorted_values is a vector
    n_values=numel(sorted_values);
    nan_msk=isnan(sorted_values);
    nan_count=sum(nan_msk);
    non_nan_count=numel(sorted_values)-nan_count;

    % first set ranks for values without ties
    ranks=sort_idx+NaN;
    ranks(sort_idx(1:non_nan_count))=1:non_nan_count;

    % now deal with ties
    tie_msk=sorted_values(2:end)==sorted_values(1:(end-1));
    tie_idx=find(tie_msk);
    tie_count=numel(tie_idx);

    k=0;
    while k<tie_count
        k=k+1;

        tie_start=tie_idx(k);
        tie_end=tie_start+1;

        while tie_end<n_values ...
                && sorted_values(tie_end)==sorted_values(tie_end+1)
            tie_end=tie_end+1;
            k=k+1;
        end

        tie_value=(tie_start+tie_end)/2;
        pos=tie_start+(0:(tie_end-tie_start));
        ranks(sort_idx(pos))=tie_value;
    end


function ranks=singleton_ranks(data)
    % all ranks are either NaN or 1
    ranks=ones(size(data));
    ranks(isnan(data))=NaN;


function check_inputs(data, dim)
    if ~isnumeric(data)
        error('First input must be numeric')
    end

    if ~(isnumeric(dim) ...
            && isscalar(dim) ...
            && round(dim)==dim ...
            && dim>0)
        error('Second argument must be numeric integer');
    end
