function data=generate_random_deterministic(shape, fhandle)
% generate deterministic data. default with gaussian distribution
if nargin<2, fhandle=@randn; end

rng_state=rng; % store state

try
    rng('default') % get default state
    data=fhandle(shape); % generate random data
catch
end

% ensure that state is restored even if randn raised an exception
rng(rng_state);
