function s=cosmo_squareform(x, varargin)
% converts pair-wise distances between matrix and vector form
%
% s=cosmo_squareform(x[, direction])
%
% Inputs:
%    x           One of:
%                - NxN distance matrix; x must be symmetric and have zeros
%                  on the diagonal
%                - 1xM distance vector
%    direction   Optional. If provided it must be 'tovector' (if x is a
%                matrix) or 'tomatrix' (if x is a vector). If not provided
%                it is set to 'tovector' if x is a matrix and to 'tomatrix'
%                if x is a vector
%
% Returns:
%    s           One of:
%                - NxN distance matrix, if direction=='tomatrix'
%                - 1xM distance vector, if direction=='tovector'
%                it must hold that N*(N-1)/2=M
%
% Notes:
%  - this function provides the same functionality as the built-in function
%    ''squareform'' in the matlab stats toolbox.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    check_input(x);

    direction=get_direction(x,varargin{:});

    switch direction
        case 'tomatrix'
            s=to_matrix(x);

        case 'tovector'
            s=to_vector(x);

        otherwise
            error(['illegal direction argument, must be one of ', ...
                        '''tomatrix'',''tovector''']);
    end


function check_input(x)
    if numel(size(x))~=2
        error('first input must be matrix or vector');
    end

    if ~(islogical(x) || isnumeric(x))
        error(['Unsupported data type ''%s''; only numeric '...
                'and logical arrays are supported']', class(x));
    end


function s=to_vector(x)

    [n_rows,n_columns]=size(x);
    if n_rows~=n_columns
        error('direction ''to_vector'' requires a square matrix as input');
    end

    dg=diag(x);
    if any(dg)
        error('square matrix must be all zero on diagonal');
    end

    if ~isequal(x,x');
        error('square matrix must be symmetric');
    end

    msk=bsxfun(@gt,(1:n_rows)',1:n_rows);

    s=x(msk);
    s=s(:)';


function s=to_matrix(x)
    if isempty(x)
        s=[];
        return;
    end
    if ~isvector(x)
        error('direction ''to_matrix'' requires a vector as input');
    end
    n=numel(x);

    % side*(side+1)/2=n, solve for side>0
    side=(1+sqrt(1+8*n))/2;
    if ~isequal(side, round(side))
        error(['size %d of input vector is not correct for '...
                'the number of elements below diagonal of a '...
                'square matrix'], n);
    end
    msk=bsxfun(@gt,(1:side)',1:side);

    if islogical(x)
        s=false(side);
        s(msk)=x;
        s=s|s';
    elseif isnumeric(x)
        s=zeros(side);
        s(msk)=x;
        s=s+s';
    end

function direction=get_direction(x,varargin)
    if numel(varargin)<1
        sz=size(x);
        if sz(1)==sz(2) && sz(1)~=1
            direction='tovector';
        else
            direction='tomatrix';
        end
    elseif ischar(varargin{1})
        direction=varargin{1};
    else
        error('second argument must be a string');
    end






