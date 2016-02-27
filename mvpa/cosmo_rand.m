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
%   - when using the 'seed' option, this function gives identical output
%     under both matlab and octave. To achieve this, the PRNG is set to a
%     different state for the two platforms
%   - this function uses the Mersenne twister algorithm by default, even
%     when 'seed' is used (unlike Matlab and Octave).
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    [sizes,seed]=process_input(varargin{:});

    randomizer=@rand; % default
    if seed~=0
        is_matlab=cosmo_wtf('is_matlab');

        if is_matlab
            rng_state=get_mersenne_state_from_seed(seed, is_matlab);

            stream=RandStream('mt19937ar','Seed',rng_state.Seed);
            stream.State=rng_state.State;

            randomizer=@stream.rand;
        else
            % preserve old PRNG state
            orig_rng_state=rand('state');
            cleaner=onCleanup(@()rand('state',orig_rng_state));

            % set random number generation state
            rng_state=get_mersenne_state_from_seed(seed, is_matlab);
            rand('state',rng_state);
        end
    end

    result=randomizer(sizes);


function rng_state=get_mersenne_state_from_seed(seed, is_matlab)
    % set the PRNG of the mersenne twister based on seed
    %
    % based on pseudo-code from wikipedia:
    % http://en.wikipedia.org/wiki/Mersenne_twister
    persistent cached_seed
    persistent cached_rng_state

    if isequal(cached_seed,seed)
        rng_state=cached_rng_state;
        return;
    end

    max_uint32=2^32-1;
    state=uint64(zeros(625,1));
    state(1)=bitand(uint64(seed),max_uint32);

    mersenne_mult=uint64(1812433253);

    for j=1:623
        v=mersenne_mult.*bitxor(state(j),bitshift(state(j),-30))+uint64(j);
        state(j+1)=bitand(v,max_uint32);
    end

    state(end)=1;

    if is_matlab
        % reverse counter relative to Octave
        % (this is undocumented in both Matlab and Octave)
        state(end)=uint64(625)-state(end);

        % matlab uses a struct to set the state
        rng_state=struct();
        rng_state.State=uint32(state);
        rng_state.Type='twister';
        rng_state.Seed=uint32(0);
    else
        % octave uses a vector to set the state
        rng_state=state;
    end

    cached_rng_state=rng_state;
    cached_seed=seed;



function [sizes,seed]=process_input(varargin)
    persistent cached_varargin;
    persistent cached_sizes;
    persistent cached_seed;
    if isequal(varargin,cached_varargin)
        sizes=cached_sizes;
        seed=cached_seed;
        return;
    end

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
            ensure_positive_scalar(k,value);

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

    cached_varargin=varargin;
    cached_sizes=sizes;
    cached_seed=seed;

function ensure_positive_scalar(k,arg)
    ensure_positive_vector(k,arg);
    if ~isscalar(arg)
        error('argument at position %d is not a scalar',k);
    end

function ensure_positive_vector(k,arg)
    if ~isvector(arg) || ~isnumeric(arg) || ~(all(arg>=0))
        error('argument at position %d is not positive',k);
    end
