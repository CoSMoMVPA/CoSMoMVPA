function [cell_indices, unique_values]=cosmo_index_unique(values)
% index unique (combinations of) elements
%
% [cell_indices, unique_values]=cosmo_index_unique(values)
%
% Input:
%   values              either:
%                       - cell with K elements, each of which must be
%                         either a vector with M elements or a cell with
%                         M strings (each element in each cell is treated
%                         as a row); or
%                       - MxK matrix
%
% Returns:
%   cell_indices        Ux1 cell, if along the input there are U unique
%                       combinations of values (element-wise). The K-th
%                       element has U_K indices in the range 1:M indicating
%                       the rows in the input have the same value
%   unique_values       either:
%                       - Kx1 cell, each with U elements, containing the
%                         unique combinations of values of the input
%                         [if the input is a cell]; or
%                       - UxK cell, containing the unique rows in the input
%
% Examples:
%     [i,u]=cosmo_index_unique({[3 2 2 2 1],[3 2 3 3 3]});
%     cosmo_disp(i);
%     > { [ 5 ]
%     >   [ 2 ]
%     >   [ 3
%     >     4 ]
%     >   [ 1 ] }
%     cosmo_disp(u);
%     > { [ 1    [ 3
%     >     2      2
%     >     2      3
%     >     3 ]    3 ] }
%
%     % the same operation in matrix operation (input is transposed)
%     [i,u]=cosmo_index_unique([3 2 2 2 1;3 2 3 3 3]');
%     cosmo_disp(i);
%     > { [ 5 ]
%     >   [ 2 ]
%     >   [ 3
%     >     4 ]
%     >   [ 1 ] }
%     cosmo_disp(u);
%     > [ 1         3
%     >   2         2
%     >   2         3
%     >   3         3 ]
%
%     % it also works if (some of the) input contains cell strings
%     [i,u]=cosmo_index_unique({{'ccc','bb','bb','bb','a'},...
%                                 [4 3 4 4 4]});
%     cosmo_disp(i);
%     > { [ 5 ]
%     >   [ 2 ]
%     >   [ 3
%     >     4 ]
%     >   [ 1 ] }
%     cosmo_disp(u);
%     > { { 'a'      [ 4
%     >     'bb'       3
%     >     'bb'       4
%     >     'ccc' }    4 ] }
%
% NNO Sep 2014

    return_unique_values=nargout>=2;

    [idxs,input_is_array]=index_unique_per_value(values);

    [idxs_sorted,i]=sortrows(idxs);

    msk=[true; any(diff(idxs_sorted,1),2)];
    unq_pos=find(msk);

    nidxs=size(idxs,1);
    cell_sizes=[diff([unq_pos;(nidxs+1)])];

    % convert to cell representation
    %cell_indices=mat2cell(i,cell_sizes,1);
    cell_indices=quick_mat2cell_vec(i,cell_sizes);
    %assertEqual(cell_indices,cell_indices2);

    if isempty(i)
        singleton_idx=idxs;
    else
        singleton_idx=i(unq_pos);
    end

    if return_unique_values
        unique_values=get_unique_values(values,singleton_idx,...
                                                input_is_array);
    end

function c=quick_mat2cell_vec(i, cell_sizes)
    n=numel(cell_sizes);
    c=cell(n,1);
    pos=0;
    for k=1:n
        ncell=cell_sizes(k);
        c{k}=i(pos+(1:ncell));
        pos=pos+ncell;
    end



function unique_values=get_unique_values(values,first_idx,input_is_array)
    if input_is_array
        % return matrix
        unique_values=values(first_idx,:);
    else
        % return cell with values
        ndim=numel(values);
        unique_values=cell(1,ndim);
        for k=1:ndim
            vdim=cosmo_slice(values{k}(:),first_idx);
            unique_values{k}=vdim;
        end
    end

function y=array2cell(x)
    if ~(islogical(x) || isnumeric(x)) || numel(size(x))>2
        error('input must be matrix or cell');
    end
    [nrows,ncols]=size(x);
    y=mat2cell(x,nrows,ones(1,ncols));

function [idxs,input_is_array]=index_unique_per_value(values)
    % finds the indices of unique elements for each element
    % in values (that must be a cell)
    input_is_array=~iscell(values);
    if input_is_array
        values=array2cell(values);
    end

    ndim=numel(values);
    for k=1:ndim
        vs=values{k};

        if ~is_1d(vs)
            error('element %d is not one-dimensional',k);
        end

        [unused,unused,idx]=unique(vs);

        % ensure all elements in values have the same size
        nv=numel(idx);
        if k==1
            nv_first=nv;
            idxs=zeros(nv,ndim);
        else
            if nv~=nv_first
                error('element %d has %d values, first has %d',...
                            k,nv,nv_first);
            end
        end

        idxs(:,k)=idx;
    end

function tf=is_1d(x)
    tf=sum(size(x)>1)<=1;
