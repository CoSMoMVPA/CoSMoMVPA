function [map_x2y, map_y2x]=cosmo_align(x,y)
% find permutation so that values in two inputs are matched
%
% [map_x2y, map_y2x]=cosmo_align(x,y)
%
% Inputs:
%   x               } both x and y must be a cell with K elements, each
%   y               } being a vector or a cellstring with the same number
%                     of elements (say N). Alternatively it can
%                     be a single vector  or cellstrings v, which is
%                     interpreted as {v}.
%
% Outputs:
%   map_x2y           a vector with N elements, so that for all values I in
%                     1:K it holds that map_x2y(x{I}) is equal to y{I}.
%   map_y2x           a vector with N elements, so that for all values I in
%                     1:K it holds that map_y2x(y{I}) is equal to x{I}.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    [x_cell,x_label]=as_cell(x,1);
    [y_cell,y_label]=as_cell(y,2);

    ensure_matching_labels(x_label, y_label);

    nx=numel(x_cell);
    ny=numel(y_cell);

    if nx~=ny
        error(['number of elements in each cell is not equal; first '...
                    'input has %d elements, second input has %d'],...
                        nx,ny);
    end

    [xi,xv]=cosmo_index_unique(x_cell);
    [yi,yv]=cosmo_index_unique(y_cell);

    if ~isequaln(xv,yv)
        error(['the two inputs do not have the same unique '...
                    'combination of elements']);
    end

    nxi=cellfun(@numel,xi);
    nyi=cellfun(@numel,yi);

    if ~isequal(nxi,nyi)
        error(['the two inputs do have matching elements '...
                    'but their number of occurences is not matched']);
    elseif any(cellfun(@numel,xi)>1)
        error('combinations of elements are non-unique');
    end

    xv=cat(1,xi{:});
    yv=cat(1,yi{:});



    n=numel(xi);
    map_x2y=zeros(1,n);
    map_x2y(yv)=xv;

    map_y2x=zeros(1,n);
    map_y2x(xv)=yv;


function [v_cell,labels]=as_cell(v,pos)
    if iscell(v) && ~iscellstr(v)
        n=numel(v);

        for j=1:n
            ensure_vector(v{j},pos,j);
        end
        v_cell=v;
        labels=[];
    elseif isstruct(v)
        labels=sort(fieldnames(v));
        n=numel(labels);

        v_cell=cell(n,1);
        for k=1:n
            label=labels{k};
            v_value=v.(label);
            ensure_vector(v_value,pos,label);
            v_cell{k}=v_value;
        end
    else
        ensure_vector(v,pos,1);
        v_cell={v(:)};
        labels=[];
    end


function ensure_vector(v,pos,i)
    if ~isvector(v)
        msg='only input with vectors is supported';
    elseif ~(isnumeric(v) || iscellstr(v))
        msg=['only inputs with numeric vectors or cellstrings '...
                'are supported'];
    else
        % all fine
        return
    end

    if ischar(i)
        elem_str=['field ' i];
    else
        elem_str=sprintf('element %d', i);
    end

    % throw error
    error('input %d, %s: %s',pos,elem_str,msg);

function ensure_matching_labels(x_label, y_label)
    if ~isequal(x_label, y_label)
        if iscellstr(x_label) && iscellstr(y_label)
            error(['field name mismatch between two inputs: '...
                    '[%s] ~= [%s]'],...
                    cosmo_strjoin(x_label),cosmo_strjoin(y_label));
        else
            error(['either both inputs must be cells or vectors, ',...
                    'or both must be structs']);
        end
    end


