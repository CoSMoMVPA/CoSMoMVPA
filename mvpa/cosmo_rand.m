function result=cosmo_rand(varargin)
% generate uniform pseudo-random numbers, optionally using a seed value
%
% result=cosmo_rand(s1,...,sN,['seed',seed])
%
% Input:
%    s*              scalar or vector indicating dimensions of the result
%    'seed', seed    (optional) if provided, use this seed value for
%                    pseudo-random number generation
%
% Output:
%    result          array of size s1 x s2 x ... sN. If the seed option is
%                    used, repeated calls with the same seed and element
%                    dimensions gives the same result
% Example:
%     % generate 2x2 pseudo-random number matrices twice, just like 'rand'
%     % (repeated calls give different outputs)
%     x1=cosmo_rand(2,2);
%     x2=cosmo_rand(2,2);
%     isequal(x1,x2)
%     > false
%     %
%     % as above, but specify a seed; repeated calls give the same output
%     x3=cosmo_rand(2,2,'seed',314);
%     x4=cosmo_rand(2,2,'seed',314);
%     isequal(x3,x4)
%     > true
%     %
%     % using a different seed gives a different output
%     x5=cosmo_rand(2,2,'seed',315);
%     isequal(x3,x5)
%     > false
%
%
% Notes:
%   - this function behaves identically to the builtin 'rand' function,
%     except that it supports a 'seed' option, which allows for
%     deterministic pseudo-number generation
%
% NNO Jan 2015

    [sizes,seed]=process_input(varargin{:});

    if seed~=0
        if cosmo_wtf('is_matlab')
            % matlab
            rng_state=rng();
            cleaner=onCleanup(@()rng(rng_state));
            rng(seed);
        else
            % octave
            rng_state=randn('state');
            cleaner=onCleanup(@()randn('state',rng_state));
            randn('seed',seed);
        end
    end

    result=rand(sizes);


function [sizes,seed]=process_input(varargin)
    n=numel(varargin);

    seed=0;
    sizes_cell=cell(1,n);

    % process each argument
    k=0;
    while k<n
        k=k+1;
        arg=varargin{k};
        if isnumeric(arg)
            ensure_positive_vector(k,arg);
            sizes_cell{k}=arg(:)';
        elseif ischar(arg)
            k=k+1;
            if k>n
                error('missing value after key ''%s''', arg);
            end
            value=varargin{k};
            ensure_positive_scalar(k,value)

            switch arg
                case 'seed'
                    seed=value;
                otherwise
                    error('unsupported key ''%s''', arg);
            end
        else
            error('illegal input at position %d', k);
        end
    end

    sizes=[sizes_cell{:}];

    % no size provided, output is scalar
    if isempty(sizes)
        sizes=1;
    end

function ensure_positive_scalar(k,arg)
    ensure_positive_vector(k,arg);
    if ~isscalar(arg)
        error('argument at position %d is not a scalar',k);
    end

function ensure_positive_vector(k,arg)
    if ~isvector(arg) || ~isnumeric(arg) || ~(all(arg>=0))
        error('argument at position %d is not positive',k);
    end
