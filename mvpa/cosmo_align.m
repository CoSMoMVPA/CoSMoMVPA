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
% NNO Feb 2015

    x_cell=as_cell(x,1);
    y_cell=as_cell(y,2);

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
    end

    xv=cat(1,xi{:});
    yv=cat(1,yi{:});



    n=numel(xi);
    map_x2y=zeros(1,n);
    map_x2y(yv)=xv;

    map_y2x=zeros(1,n);
    map_y2x(xv)=yv;


    function v_cell=as_cell(v,pos)
        if iscell(v) && ~iscellstr(v)
            n=numel(v);

            for j=1:n
                ensure_vector(v{j},pos,j);
            end
            v_cell=v;
        else
            ensure_vector(v,pos,1);
            v_cell={v(:)};
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


        % throw error
        error('input %d, element %d: %s',pos,i,msg);
