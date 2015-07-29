function [data, targets] = cosmo_meansamples(data, targets, nmean_trials)
%MEG_AVERAGE_TRIALS averages the trials in data. It averages nmean_trials
%for each condition until the trials are exhausted. If there remains less
%than nmean_trials, all of them are averaged.
%The function looks for conditions as specified into the field .trialinfo
%by default. A different parameter can be passed with e.g., parameter =
%'targets'.
%data must be a timelocked FieldTrip structure (from FT_TIMELOCKANALYSIS).
%Example call:
%  data_avg = meg_average_trials(data, 5);
%
%  data_avg = meg_average_trials(data, 5, 'targets');

% MVdOC Nov 2014
if size(data, 1) ~= length(targets)
    error('data and targets have different number of elements');
end

unique_targets = unique(targets);
nunique_targets = length(unique_targets);

% compute all the indices first
indices = arrayfun(@(x) find(targets == x), ...
    unique_targets', 'UniformOutput', 0);

% check that we have enough data to average across all conditions
min_ntrl = min(cell2mat(cellfun(@(x) length(x), indices, ...
    'UniformOutput', 0)));

if nmean_trials > min_ntrl
    error(['Cannot average %d trials, minimum number of trials in ' ...
    'one of the conditions is %d'], nmean_trials, min_ntrl);
end

out_avg_trial = cell([nunique_targets, 1]);
out_avg_targets = cell([nunique_targets, 1]);
[nsamples, nfeatures] = size(data);

for icond = 1:nunique_targets
    this_cond = unique_targets(icond);
    idx = indices{icond};
    temp_trial = data(idx, :);
    
    nidx = length(idx);
    nremainder_trials = rem(nidx, nmean_trials);
    naveraged_trials = floor(nidx/nmean_trials);
    
    start = 1;
    if nremainder_trials ~= 0
        avg_trial = zeros(naveraged_trials+1, nfeatures);
        avg_trialinfo = ones([naveraged_trials+1, 1])*this_cond;
        rand_idx = randsample(1:nidx, nremainder_trials);
        % average these trials
        avg_trial(1, :, :) = mean(temp_trial(rand_idx, :), 1);
        % remove these trials
        temp_trial(rand_idx, :) = [];
        start = 2;
    else
        avg_trial = zeros(naveraged_trials, nfeatures);
        avg_trialinfo = ones([naveraged_trials, 1])*this_cond;
    end
    for j = start:naveraged_trials+(start-1);
        nidx = size(temp_trial, 1);
        rand_idx = randsample(1:nidx, nmean_trials);
        avg_trial(j, :) = mean(temp_trial(rand_idx, :), 1);
        % remove these trials
        temp_trial(rand_idx, :) = [];
    end
    
    out_avg_trial{icond} = avg_trial;
    out_avg_targets{icond} = avg_trialinfo;
end

data = cell2mat(out_avg_trial);
targets = cell2mat(out_avg_targets);

% check we have the same number of samples for each target
% TODO: is this a good way to check that the chunk is balanced after
% meaning?
ntar = zeros(1, numel(unique(targets)));
for tar = unique(targets)'
    ntar(tar) = sum(targets == tar);
end
assert(length(unique(tar)) == 1);