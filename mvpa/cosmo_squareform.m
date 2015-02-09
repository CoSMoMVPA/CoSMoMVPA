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
% NNO Jul 2014

    check_input(x)
    direction=get_direction(x,varargin{:});

    if isempty(x)
        s=x;
        return
    end

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
    if ~ismatrix(x)
        error('first input must be matrix or vector');
    end

    if ~(islogical(x) || isnumeric(x))
        error(['Unsupported data type ''%s''; only numeric '...
                'and logical arrays are supported']', class(x));
    end


function s=to_vector(x)
    [side,side_]=size(x);
    if side~=side_
        error('direction ''to_vector'' requires a square matrix as input');
    end



    dg=diag(x);
    if any(dg)
        error('square matrix must be all zero on diagonal');
    end

    if ~isequal(x,x');
        error('square matrix must be symmetric');
    end

    msk=bsxfun(@gt,(1:side)',1:side);

    s=x(msk);
    s=s(:)';


function s=to_matrix(x)
    if ~isvector(x)
        error('direction ''to_vector'' requires a vector as input');
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
    else
        error('Unsupported data type ''%s''', class(x));
    end

function direction=get_direction(x,varargin)
    if numel(varargin)<1
        if isvector(x)
            direction='tomatrix';
            return
        elseif ismatrix(x)
            direction='tovector';
            return;
        else
            error('first argument must be a matrix or vector')
        end
    elseif ischar(varargin{1})
        direction=varargin{1};
    else
        error('second argument must be a string');
    end






