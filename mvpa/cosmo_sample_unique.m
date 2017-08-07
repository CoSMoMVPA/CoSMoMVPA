function samples=cosmo_sample_unique(k,n,count,varargin)
% sample without replacement from subsets of integers in balanced manner
%
% function samples=cosmo_sample_unique(k,n[,count,varargin])
%
% Inputs:
%   k           number of elements to return in each subset
%   n           size of integer range from which to sample
%   count       number of subsets to select (default: 1)
%   'seed', s   Use seed s for pseudo-random sampling (optional). If this
%               option is omitted, then different calls to this function
%               may (usually: will) return different results
%
%
% Output:
%   samples     k x count indices, all in the range 1:n, with the following
%               properties:
%               - each value is randomly sampled from the range 1:n
%               - each column forms a subset of 1:n (without repeats)
%               - across the entire matrix, each value in the range 1:n
%                 occurs approximately equally often
%
% Example:
%     % get 4 random subsets of 3 elements in range 1:7
%     % (in this example a seed is used to get the same result upon every
%     % function call)
%     cosmo_sample_unique(3,6,4,'seed',3)
%     >      1     2     1     2
%     >      3     5     3     4
%     >      4     6     5     6
%
% Notes:
%   - this is a utility function; it does not work on dataset structures.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<3 || isempty(count)
        count=1;
    end

    ensure_scalar_nat({k,n,count});
    if k>n
        error(['First argument (%d) cannot be greater than '...
                    'second argument (%d)'],k,n);
    end

    opt=cosmo_structjoin(varargin{:});

    % random elements, each column is a permutation of 1:count
    rs_mat=random_permutations(n,count+1,opt);

    % vectorize
    rs=rs_mat(:);

    % allocate space for output
    samples=zeros(k,count);

    % keep track of which elements in rs were visited
    visited=false((k+1)*count,1);

    first_non_visited_pos=1;
    in_bin=false(n,k); % re-use this for each column
    for col=1:count
        % no elements added so far
        in_bin(:)=false;

        pos=first_non_visited_pos;
        for row=1:k
            % avoid duplicates in in_bin
            while visited(pos) || in_bin(rs(pos))
                pos=pos+1;
            end

            r=rs(pos);
            in_bin(r)=true;
            samples(row,col)=r;
            visited(pos)=true;
        end

        % update first_non_visited pos
        while visited(first_non_visited_pos)
            first_non_visited_pos=first_non_visited_pos+1;
        end
    end

    samples=sort(samples,1);

function r=random_permutations(n,count,opt)
    % output r has in each column the values 1:count in randomly permuted
    % order
    if isfield(opt,'seed') && ~isempty(opt.seed)
        args={'seed',opt.seed};
    else
        args={};
    end

    v=cosmo_rand(n,count,args{:});
    [unused,r]=sort(v,1);


function ensure_scalar_nat(vs)
    for k=1:numel(vs)
        v=vs{k};

        if ~(isnumeric(v) && isscalar(v) && v>0 && round(v)==v)
            error('Argument %d must be positive scalar integer',k);
        end
    end