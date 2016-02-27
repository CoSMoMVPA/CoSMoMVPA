%% MEEG time-frequency searchlight
%
% This example shows MVPA analyses performed on MEEG data, using a
% searchlight across the time, frequency and channel dimensions
%
% The input dataset involved a paradigm with electrical median nerve
% stimulation for durations of 2s at 20Hz.
%
% The code presented here can be adapted for other MEEG analyses, but
% there are a few potential caveats:
% * assignment of targets (labels of conditions) is based here on
%   stimulation periods versus pre-stimulation periods. In typical
%   analyses the targets should be based on different trial conditions, for
%   example as set a FieldTrip .trialinfo field.
% * assignment of chunks (parts of the data that are assumed to be
%   independent) is based on a trial-by-trial basis. For cross-validation,
%   the number of chunks is reduced to two to speed up the analysis.
% * the time window used for analyses is rather small. This means that in
%   particular for time-freq analysis a lot of data is missing, especially
%   for early and late timepoints in the lower frequency bands. For typical
%   analyses it may be preferred to use a wider time window.
% * the current examples do not perform baseline corrections or signal
%   normalizations, which may reduce discriminatory power.
%
% Note: running this code requires FieldTrip.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


%% get timelock data in CoSMoMVPA format

% set configuration
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'meg_20hz');

% show dataset information
readme_fn=fullfile(data_path,'README');
cosmo_type(readme_fn);

% reset citation list
cosmo_check_external('-tic');

% load data
data_fn=fullfile(data_path,'subj102_B01_20Hz_timefreq.mat');
data_tf=load(data_fn);

% convert to cosmomvpa struct
ds_tf=cosmo_meeg_dataset(data_tf);

% set the target (trial condition)
ds_tf.sa.targets=ds_tf.sa.trialinfo(:,1); % 1=pre, 2=post

% set the chunks (independent measurements)
% in this dataset, the first half of the samples (in order)
% are the post-trials;
% the second half the pre-trials
ds_tf.sa.chunks=[(1:145) (1:145)]';


% in addition give a label to each trial
index2label={'pre','post'}; % 1=pre, 2=peri/post
ds_tf.sa.labels=cellfun(@(x)index2label(x),num2cell(ds_tf.sa.targets));

% just to check everything is ok
cosmo_check_dataset(ds_tf);

% get rid of features with at least one NaN value across samples
fa_nan_mask=sum(isnan(ds_tf.samples),1)>0;
fprintf('%d / %d features have NaN\n', ...
            sum(fa_nan_mask), numel(fa_nan_mask));
ds_tf=cosmo_slice(ds_tf, ~fa_nan_mask, 2);


%% set MVPA parameters
fprintf('The input has feature dimensions %s\n', ...
                cosmo_strjoin(ds_tf.a.fdim.labels,', '));


% set chunks
% again for speed just two chunks
% (targets were already set above)
nchunks=2;
ds_tf.sa.chunks=cosmo_chunkize(ds_tf, nchunks);

% define neighborhood parameters for each dimension

% channel neighborhood uses meg_combined_from_planar, which means that the
% input are planar channels but the output has combined-planar channels.
% to use the magnetometers, use 'meg_axial'
chan_type='meg_combined_from_planar';
chan_count=10;        % use 10 channel locations (relative to the combined
                      % planar channels)
                      % as we use meg_combined_from_planar there are
                      % 20 channels in each searchlight because
                      % gradiometers are paired
time_radius=2; % 2*2+1=5 time bines
freq_radius=4; % 4*2+1=9 freq bins


% define the neighborhood for each dimensions
chan_nbrhood=cosmo_meeg_chan_neighborhood(ds_tf, 'count', chan_count, ...
                                                'chantype', chan_type);
freq_nbrhood=cosmo_interval_neighborhood(ds_tf,'freq',...
                                            'radius',freq_radius);
time_nbrhood=cosmo_interval_neighborhood(ds_tf,'time',...
                                            'radius',time_radius);

% cross neighborhoods for chan-time-freq searchlight
nbrhood=cosmo_cross_neighborhood(ds_tf,{chan_nbrhood,...
                                        freq_nbrhood,...
                                        time_nbrhood});

% print some info
nbrhood_nfeatures=cellfun(@numel,nbrhood.neighbors);
fprintf('Features have on average %.1f +/- %.1f neighbors\n', ...
            mean(nbrhood_nfeatures), std(nbrhood_nfeatures));

% only keep features with at least 10 neighbors
% (some have zero neighbors - in particular, those with low frequencies
% early or late in time)
center_ids=find(nbrhood_nfeatures>10);

% for illustration purposes use the split-half measure because it is
% relatively fast - but clasifiers can also be used
measure=@cosmo_correlation_measure;

% split-half, as there are just two chunks
% (when using a classifier, do not use 'half' but the number of chunks to
% leave out for testing, e.g. 1).
measure_args=struct();
measure_args.partitions=cosmo_nchoosek_partitioner(ds_tf,'half');


%% run searchlight
sl_tf_ds=cosmo_searchlight(ds_tf,nbrhood,measure,measure_args,...
                                      'center_ids',center_ids);
%% visualize results

% deduce layout from output
layout=cosmo_meeg_find_layout(sl_tf_ds);
fprintf('The output uses layout %s\n', layout.name);

% map to FT struct for visualization
sl_tf_ft=cosmo_map2meeg(sl_tf_ds);

% show figure
figure()
cfg = [];
if cosmo_wtf('is_octave')
    % GNU Octave does not show data when labels are shown
    cfg.interactive='no';
    cfg.showlabels='no';
else
    % Matlab supports interactive viewing and labels
    cfg.interactive = 'yes';
    cfg.showlabels = 'yes';
end
cfg.zlim='maxabs';
cfg.layout       = layout;
ft_multiplotTFR(cfg, sl_tf_ft);

% Show citation information
cosmo_check_external('-cite');

