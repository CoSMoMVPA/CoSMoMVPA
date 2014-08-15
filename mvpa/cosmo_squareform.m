function s=cosmo_squareform(x, direction)
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


if nargin<2
    if numel(size(x))~=2
        error('Input must be matrix or vector');
    end

    if isvector(x)
        direction='tomatrix';
    else
        direction='tovector';
    end
end

if isempty(x)
    s=x;
    return
end

switch direction
    case 'tomatrix'
        if ~isvector(x)
            error('direction ''%s'' requires a vector as input',direction);
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

    case 'tovector'
        [side,side_]=size(x);
        if side~=side_
            error('direction ''%s'' requires a square matrix as input', ...
                                                        direction);
        end

        if ~(islogical(x) || isnumeric(x))
            error('Unsupported data type ''%s''', class(x));
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

    otherwise
        error(['illegal direction argument ''%s'', must be one of ', ...
                    '''tomatrix'',''tovector'''],direction);

end








