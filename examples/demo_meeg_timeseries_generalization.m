%% MEEG time-by-time transfer classification
%
% This example shows MVPA generalization across time. The input is a
% time-locked dataset (chan x time), the output is either:
%
% * (train_time x test_time) indicating for each combination of time points
%   in the training and test set how similar the patterns are
% * (train_time x test_time x chan), which uses a searchlight and
%   indicates for each combination of time points in the training and
%   test set how similar the patterns are in the neighborhood of each
%   channel.
%
% Results can be visualized in FieldTrip.
%
% The input dataset involved a paradigm with electrical median nerve
% stimulation for durations of 2s at 20Hz.
%
% The code presented here can be adapted for other MEEG analyses, but
% there are a few potential caveats:
%
% * assignment of targets (labels of conditions) is based here on
%   stimulation periods versus pre-stimulation periods. In typical
%   analyses the targets should be based on different trial conditions, for
%   example as set a FieldTrip .trialinfo field.
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

% set configuration
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'meg_20hz');

% show dataset information
readme_fn=fullfile(data_path,'README');
cosmo_type(readme_fn);

% reset citation list
cosmo_check_external('-tic');

% load data
data_fn=fullfile(data_path,'subj102_B01_20Hz_timelock.mat');
data_tl=load(data_fn);

% convert to cosmomvpa struct
ds_tl=cosmo_meeg_dataset(data_tl);

% set the target (trial condition)
ds_tl.sa.targets=ds_tl.sa.trialinfo(:,1); % 1=pre, 2=peri/post

% set the chunks (independent measurements)
% in this dataset, the first half of the samples (in order)
% are the post-trials;
% the second half the pre-trials
ds_tl.sa.chunks=[(1:145) (1:145)]';

% in addition give a label to each trial
index2label={'pre','post'}; % 1=pre, 2=peri/post
ds_tl.sa.labels=cellfun(@(x)index2label(x),num2cell(ds_tl.sa.targets));

% just to check everything is ok
cosmo_check_dataset(ds_tl);

%% reduce the number of time points
% to allow this example to run relatively fast, only use the 'even'
% timepoints and only use timepoints between 0 and 300 ms relative to
% stimulus onset.
% for a publication-quality analysis this step could be omitted.
msk=cosmo_dim_match(ds_tl,'time',@(x) 0<x &x<.3) & ...
                        mod(ds_tl.fa.time,2)==0;
ds=cosmo_slice(ds_tl,msk,2);
ds=cosmo_dim_prune(ds);


%% Set up chunks
% use half of the data for training and half for testing. Here both chunks
% come from the same session, but it is also possible to use different
% sessions for training and testing.
%
% For example, the train data can contain responses to auditory stimuli
% with the words 'face' and 'house', while the test session measures
% responses to visual stimuli. In that case the chunks should be assigned
% 'manually' (without cosmo_chunkize)
nchunks=2; % two chunks are required for this analysis
ds.sa.chunks=cosmo_chunkize(ds,nchunks);


%% time-by-time generalization on magneto- and gradio-meters seperately
% compute and plot accuracies for magnetometers and gradiometers separately
chan_types={'meg_axial','meg_planar'};
nchan_types=numel(chan_types);

% set arguments for the cosmo_dim_generalization_measure
measure_args=struct();

% the cosmo_dim_generalization_measure requires that another
% measure (here: the crossvalidation measure) is specified. The
% specified measure is applied for each combination of time points
measure_args.measure=@cosmo_crossvalidation_measure;

% When used ordinary, the cosmo_crossvalidation_measure itself
% requires two arguments:
% - classifier (here: LDA)
% - partitions
% However, because the cosmo_dim_generalization_measure defines
% the partitions itself, they are not set here.
measure_args.classifier=@cosmo_classify_lda;

% define the dimension over which generalization takes place
measure_args.dimension='time';

% define the radius for the time dimension. Here not just a single
% time-point is used, but also the time-point before it and the time-point
% after it.
measure_args.radius=1;

% try both channel types (axial and planar)
for k=1:nchan_types
    use_chan_type=chan_types{k};

    % get layout for mag or planar labels, and select only those channels
    ds_chan_types=cosmo_meeg_chantype(ds);
    ds_chan_idxs=find(cosmo_match(ds_chan_types,use_chan_type));
    feature_msk=cosmo_match(ds.fa.chan,ds_chan_idxs);
    ds_sel=cosmo_slice(ds, feature_msk, 2);

    % make 'time' a sample dimension
    % (this necessary for cosmo_dim_generalization_measure)
    ds_time=cosmo_dim_transpose(ds_sel,'time',1);

    fprintf('The input for channel type %s is:\n', use_chan_type)
    cosmo_disp(ds_time);

    % run transfer across time with the searchlight neighborhood
    %cdt_ds=cosmo_cartesian_dim_transfer(ds_time,'time',measure,...
    %                        'args',measure_args);
    cdt_ds=cosmo_dim_generalization_measure(ds_time,measure_args);

    fprintf('The output is:\n')
    cosmo_disp(cdt_ds);

    % unflatten the data to get train_time x test_time matrix
    [data, labels, values]=cosmo_unflatten(cdt_ds,1);

    % show the results
    figure()
    imagesc(data, [.3 .7]);
    title(sprintf('classification accuracy for %s', use_chan_type));
    colorbar();
    nticks=5;

    ytick=round(linspace(1, numel(values{1}), nticks));
    ylabel(strrep(labels{1},'_',' '));
    set(gca,'Ytick',ytick,'YTickLabel',values{1}(ytick));

    xtick=round(linspace(1, numel(values{2}), nticks));
    xlabel(strrep(labels{2},'_',' '));
    set(gca,'Xtick',xtick,'XTickLabel',values{2}(xtick));

    colorbar();
end


%% time-by-time generalization using a searchlight with correlation measure
% how many channel locations in each searchlight
nchannel_locations_searchlight=10;


% make 'time' a sample dimension (necessary for cartesian_dim_transfer)
ds_time=cosmo_dim_transpose(ds_sel,'time',1);


% use planar channels as input; output is
% like combine-planar
use_chan_type='meg_combined_from_planar';

% define searchlight neighborhood
nbrhood=cosmo_meeg_chan_neighborhood(ds_time,...
                        'count',nchannel_locations_searchlight,...
                        'chantype',use_chan_type);

fprintf('The input is:\n')
cosmo_disp(ds_time);

fprintf('The neighborhood is:\n');
cosmo_disp(nbrhood);

% set the measure to be the dim generalization measure
measure=@cosmo_dim_generalization_measure;

% define the arguments for the measure. One of them is called 'measure',
% because that measure is applied to combinations of samples in the
% train and test set
measure_args=struct();
measure_args.measure=@cosmo_correlation_measure;
measure_args.radius=1;
measure_args.dimension='time';


% run transfer across time with the searchlight neighborhood
cdt_ds=cosmo_searchlight(ds_time,nbrhood,measure,measure_args);

fprintf('The output is:\n')
cosmo_disp(cdt_ds)

% move {train,test}_time from being sample dimensions to feature
% dimensions, so they can be mapped to a fieldtrip struct
cdt_tf_ds=cosmo_dim_transpose(cdt_ds,{'train_time','test_time'},2);

fprintf('The output after transposing is:\n')
cosmo_disp(cdt_ds)

% trick fieldtrip into thinking this is a time-freq-chan dataset, by
% renaming train_time and test_time to freq and time, respectively
cdt_tf_ds=cosmo_dim_rename(cdt_tf_ds,'train_time','freq');
cdt_tf_ds=cosmo_dim_rename(cdt_tf_ds,'test_time','time');

%% Show correlation time-by-time generalization searchlight results

% determine layout
layout=cosmo_meeg_find_layout(cdt_tf_ds);


% convert to fieldtrip format
ft=cosmo_map2meeg(cdt_tf_ds);

% show train_time x test_time x chan figure
%
% * train_time is on the vertical ('freq') axis
% * test_time on the horizontal ('time') axis)
figure();
cfg = [];
cfg.interactive = 'yes';
cfg.showlabels = 'yes';
cfg.zlim=[-1 1];
cfg.layout       = layout;
ft_multiplotTFR(cfg, ft);

% show train_time x test_time figure for selected channels
figure();
cfg = [];
cfg.interactive = 'yes';
cfg.showlabels = 'yes';
cfg.zlim=[-1 1];
cfg.layout       = layout;
cfg.channel={'MEG0322+0323', 'MEG0332+0333', 'MEG0412+0413', ...
            'MEG0422+0423', 'MEG0632+0633', 'MEG0642+0643'};

ft_singleplotTFR(cfg,ft);

% show channel topology for timewindow over train_time x test_time
figure();
cfg = [];
cfg.interactive = 'yes';
cfg.xlim=[.2 .25];
cfg.ylim=[.2 .25];
cfg.zlim=[-1 1];
cfg.layout       = layout;
ft_topoplotTFR(cfg, ft);


%% show citation information

cosmo_check_external('-cite');

