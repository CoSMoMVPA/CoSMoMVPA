%% MEEG timeseries classification
%
% This example shows MVPA analyses performed on MEEG data.
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
% * assignment of chunks (parts of the data that are assumed to be
%   independent) is based on a trial-by-trial basis. For cross-validation,
%   the number of chunks is reduced to four to speed up the analysis.
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
data_fn=fullfile(data_path,'subj102_B01_20Hz_timelock.mat');
data_tl=load(data_fn);

% convert to cosmomvpa struct
ds_tl=cosmo_meeg_dataset(data_tl);

% set the target (trial condition)
ds_tl.sa.targets=ds_tl.sa.trialinfo(:,1); % 1=pre, 2=post

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

%% Prepare MVPA
% reset chunks: use four chunks
nchunks=4;
ds_tl.sa.chunks=cosmo_chunkize(ds_tl,nchunks);

% do a take-one-fold out cross validation.
% except when using a splithalf correlation measure it is important that
% the partitions are *balanced*, i.e. each target (or class) is presented
% equally often in each chunk
partitions=cosmo_nchoosek_partitioner(ds_tl,1);
partitions=cosmo_balance_partitions(partitions, ds_tl);

npartitions=numel(partitions);
fprintf('There are %d partitions\n', numel(partitions.train_indices));
fprintf('# train samples:%s\n', sprintf(' %d', cellfun(@numel, ...
                                        partitions.train_indices)));
fprintf('# test samples:%s\n', sprintf(' %d', cellfun(@numel, ...
                                        partitions.test_indices)));




%% Run time-series searchlight on magneto- and gradio-meters seperately

% try two different classification approaches:
% 1) without averaging the samples in the train set
% 2) by averaging 5 samples at the time in the train set, and re-using
%    every sample 3 times.
% (Note: As of July 2015, there is no clear indication in the literature
%  which approach is 'better'. These two approaches are used here to
%  illustrate how they can be used with a searchlight).
average_train_args_cell={{},...                                  % {  1
                         {'average_train_count',5,...            %  { 2
                                'average_train_resamplings',3}}; %  { 2
n_average_train_args=numel(average_train_args_cell);

% compute and plot accuracies for magnetometers and gradiometers separately
chantypes={'meg_axial','meg_planar'};

% in the time searchlight analysis, select the time-point itself, the two
% timepoints after it, and the two timepoints before it
time_radius=2;
nchantypes=numel(chantypes);

ds_chantypes=cosmo_meeg_chantype(ds_tl);
plot_counter=0;
for j=1:n_average_train_args
    % define the measure and its argument.
    % here a simple naive baysian classifier is used.
    % Alternative are @cosmo_classify_{svm,nn,lda}.
    measure=@cosmo_crossvalidation_measure;
    measure_args=struct();
    measure_args.classifier=@cosmo_classify_naive_bayes;
    measure_args.partitions=partitions;

    % add the options to average samples to the measure arguments.
    % (if no averaging is desired, this step can be left out.)
    average_train_args=average_train_args_cell{j};
    measure_args=cosmo_structjoin(measure_args, average_train_args);


    for k=1:nchantypes
        parent_type=chantypes{k};

        % find feature indices of channels matching the parent_type
        chantype_idxs=find(cosmo_match(ds_chantypes,parent_type));

        % define mask with channels matching those feature indices
        chan_msk=cosmo_match(ds_tl.fa.chan,chantype_idxs);

        % slice the dataset to select only the channels matching the channel
        % types
        ds_tl_sel=cosmo_dim_slice(ds_tl, chan_msk, 2);
        ds_tl_sel=cosmo_dim_prune(ds_tl_sel); % remove non-indexed channels

        % define neighborhood over time; for each time point the time
        % point itself is included, as well as the two time points before
        % and the two time points after it
        nbrhood=cosmo_interval_neighborhood(ds_tl_sel,'time',...
                                                'radius',time_radius);

        % run the searchlight using the measure, measure arguments, and
        % neighborhood defined above.
        % Note that while the input has both 'chan' and 'time' as feature
        % dimensions, the output only has 'time' as the feature dimension
        sl_map=cosmo_searchlight(ds_tl_sel,nbrhood,measure,measure_args);
        fprintf('The output has feature dimensions: %s\n', ...
                        cosmo_strjoin(sl_map.a.fdim.labels,', '));

        plot_counter=plot_counter+1;
        subplot(n_average_train_args,nchantypes,plot_counter);

        time_values=sl_map.a.fdim.values{1}; % first dim (channels got nuked)
        plot(time_values,sl_map.samples);

        ylim([.4 .8])
        xlim([min(time_values),max(time_values)]);
        ylabel('classification accuracy (chance=.5)');
        xlabel('time');

        if isempty(average_train_args)
            postfix=' no averaging';
        else
            postfix=' with averaging';
        end

        descr=sprintf('%s - %s', strrep(parent_type,'_',' '), postfix);
        title(descr);
    end
end
% Show citation information
cosmo_check_external('-cite');

