function rp=cosmo_randperm(n,varargin)
% generate random permutation of integers
%
% cosmo_randperm(n[,count][,'seed',seed])
%
% Inputs:
%   n                       Maximum value of output
%   count                   (optional) number of elements to return; count
%                           must not be larger than n.
%                           Default: count=n
%   'seed',seed             (optional) use seed for determistic
%                           pseudo-random number generation. If provided
%                           then subsequent calls to this function with the
%                           same input arguments will always give the same
%                           output. If not provided, then subsequent calls
%                           will almost always give different outputs
%
% Output:
%   rp                      row vector with count elements, with all
%                           numbers in the range 1:n. Numbers are sampled
%                           from 1:n without replacement, in other words rp
%                           does not contain repeats.
%

    [n,k,seed]=process_input(n,varargin{:});
    if isempty(seed)
        seed_arg={};
    else
        seed_arg={'seed',seed};
    end

    [unused,rp]=sort(cosmo_rand(1,n,seed_arg{:}));
    if ~isempty(k)
        if k>n
            error('second argument cannot be larger than first argument');
        end

        rp=rp(1:k);
    end


function [n,k,seed]=process_input(n,varargin)
    k=[];
    seed=[];

    ensure_is_int(n,'n');

    % progress remaining arguments
    n_arg=numel(varargin);
    j=0;
    while j<n_arg
        j=j+1;
        arg=varargin{j};
        if isnumeric(arg)
            ensure_is_int(arg,'count');
            if ~isempty(k)
                error('count argument provided multiple times');
            end
            k=arg;

        elseif ischar(arg)
            if j+1>n_arg
                error('missing value after ''%s'' argument',arg);
            end

            switch arg
                case 'seed'
                    if ~isempty(seed)
                        error('seed argument provided multiple times');
                    end
                    j=j+1;
                    value=varargin{j};
                    ensure_is_int(value,arg);
                    seed=value;
                otherwise
                    error('illegal keyword ''%s''',arg);
            end

        else
            error('illegal argument type %s at position %d',...
                        class(arg),j);
        end
    end

function ensure_is_int(value,label)
    if ~(isnumeric(value) && ...
            isscalar(value) && ...
            value>=0 && ...
            round(value)==value);
        error('''%s'' argument must be non-negative integer',label)
    end








