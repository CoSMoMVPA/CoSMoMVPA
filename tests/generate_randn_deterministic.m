function data=generate_randn_deterministic(shape)
% generate deterministic data with gaussian distribution

rng_state=rng; % store state

try
    rng('default') % get default state
    data=randn(shape); % generate random data
catch
end

% ensure that state is restored even if randn raised an exception
rng(rng_state); 