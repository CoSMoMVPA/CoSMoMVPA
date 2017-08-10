%% MEEG time-lock searchlight
%
% This example shows MVPA analyses performed on MEEG data.
%
% The input dataset involved a paradigm where a participant saw
% images of six object categories.
%
%
% The code presented here can be adapted for other MEEG analyses, but
% there please note:
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
data_path=fullfile(config.tutorial_data_path,'meg_obj6');

% show dataset information
readme_fn=fullfile(data_path,'README');
cosmo_type(readme_fn);

% reset citation list
cosmo_check_external('-tic');

% load preprocessed data
data_fn=fullfile(data_path,'meg_obj6_s00.mat');
data_tl=load(data_fn);

% Show data_tl
% >@@>
cosmo_disp(data_tl);
% <@@<

%%

% convert to cosmomvpa struct, using cosmo_meeg_dataset
% >@@>
ds=cosmo_meeg_dataset(data_tl);
% <@@<

% show the dataset
% >@@>
cosmo_disp(ds);
% <@@<


%%

% set the target (trial condition)
% Hint: use the first column from ds.sa.trialinfo
ds.sa.targets=ds.sa.trialinfo(:,1); % 6 categories

% set the chunks (independent measurements)
% all trials are here considered to be independent
nsamples=size(ds.samples,1);
ds.sa.chunks=(1:nsamples)';

% in addition give a label to each trial
index2label={'body','car','face','flower','insect','scene'};
ds.sa.labels=cellfun(@(x)index2label(x),num2cell(ds.sa.targets));

% just to check everything is ok
cosmo_check_dataset(ds);


%% Count number of channels, time points and trials
% >@@>
fprintf('There are %d channels, %d time points and %d trials\n',...
        numel(unique(ds.fa.chan)),numel(unique(ds.fa.time)),...
        size(ds.samples,1));
% <@@<
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Part I: compute difference between faces and scenes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For each time point and sensor; then visualize the results
% for the magnetometer (meg_axial) sensors.

% slice 'ds' twice to get 'ds_face' and 'ds_scene', each with only trials
% from the face and scene categories

% >@@>
ds_face=cosmo_slice(ds,cosmo_match(ds.sa.labels,'face'));
ds_scene=cosmo_slice(ds,cosmo_match(ds.sa.labels,'scene'));
% <@@<

% prepare dataset for output
ds_faceVSscene=cosmo_slice(ds_face,1);
ds_faceVSscene.sa=struct(); % destroy sample attributes

% Compute difference between average of faces versus average of scenes;
% store the result in the samples field of ds_faceVSscene
% >@@>
ds_faceVSscene.samples=mean(ds_face.samples)-mean(ds_scene.samples);
% <@@<

% Convert ds_faceVSscene to a fieldtrip structure and convert
ft_faceVSscene=cosmo_map2meeg(ds_faceVSscene);
%%
% Use FieldTrip to visualize the face versus house contrast
chantype='meg_axial';
layout=cosmo_meeg_find_layout(ds_faceVSscene,'chantype',chantype);

figure();
cfg=struct();
cfg.interactive='yes';
cfg.zlim=[-1 1];
cfg.layout=layout;

% show figure with plots for each sensor
ft_multiplotER(cfg, ft_faceVSscene);
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Part 2: run searchlight over time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set MVPA parameters
fprintf('The input has feature dimensions %s\n', ...
                cosmo_strjoin(ds.a.fdim.labels,', '));

% only select relevant time period and sensors
sensor_posterior_axial={'MEG1631', 'MEG1641', 'MEG1731', 'MEG1841', ...
                        'MEG1911', 'MEG1921', 'MEG1941', 'MEG2231', ...
                        'MEG2311', 'MEG2321', 'MEG2341', 'MEG2431', ...
                        'MEG2441', 'MEG2511', 'MEG2531'};

% define the mask
msk=cosmo_dim_match(ds,'time',@(t) t>=-.1 & t<=.4,...
                        'chan',sensor_posterior_axial);

% first slice the dataset, then use cosmo_dim_prune to avoid using
% non-selected data
% >@@>
ds_sel=cosmo_slice(ds,msk,2);
ds_sel=cosmo_dim_prune(ds_sel);
% <@@<

% define the neighborhood for time with a time radius of 2 time points
% Hint: use cosmo_interval_neighborhood

% >@@>
time_nbrhood=cosmo_interval_neighborhood(ds_sel,'time','radius',2);
% <@@<

% Define the measure to be cosmo_crossvalidation_measure
% >@@>
measure=@cosmo_crossvalidation_measure;
% <@@<

% Define the partitioning scheme using
% cosmo_independent_samples_partitioner.
% Use 'fold_count',5 to use 5 folds,
% and use 'test_ratio',.2 to use 20% of the data for testing (and 80% for
% training) in each fold.

% >@@>
partitions=cosmo_independent_samples_partitioner(ds,...
                                    'fold_count',5,...
                                    'test_ratio',.2);
% <@@<

% Use the LDA classifier and the partitions just defined.
measure_args=struct();
measure_args.partitions=partitions;
measure_args.classifier=@cosmo_classify_lda;

ds_sl=cosmo_searchlight(ds_sel,time_nbrhood,measure,measure_args);

plot(ds_sl.a.fdim.values{1},ds_sl.samples)
xlabel('time');
ylabel('classification accuracy');


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Part III: channel-time searchlight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% select limited time period
msk=cosmo_dim_match(ds,'time',@(t) t>=-.1 & t<=.4);

% first slice the dataset using the mask and assign to 'ds_sel'
ds_sel=cosmo_slice(ds,msk,2);

% Now use cosmo_dim_prune to avoid attempts to using
% non-selected data in the searchlight
ds_sel=cosmo_dim_prune(ds_sel);

% Set the seachlight parameters
chan_count=10; % 10 center channels in each searchlight
time_radius=2; % 2*2+1=5 time bins
chan_type='meg_combined_from_planar';

% define the neighborhood for each dimensions
% First, set 'chan_nbrhood' using cosmo_meeg_chan_neighborhood,
% and use the 'chantype' and 'count paramters to set the channel type
% and the number of sensors in each searchlight.
% >@@>
chan_nbrhood=cosmo_meeg_chan_neighborhood(ds_sel, 'count', chan_count, ...
                                                'chantype', chan_type);
% <@@<

% Second, set 'time_nbrhood' using cosmo_interval_neighborhood,
% using the 'time' dimension
% >@@>
time_nbrhood=cosmo_interval_neighborhood(ds_sel,'time',...
                                            'radius',time_radius);
% <@@<

% cross neighborhoods for chan-time searchlight
% Hint: use cosmo_cross_neighborhood, and use chan_nbrhood and time_nbrhood
% (in that order) in a cell as the second argument
% >@@>
nbrhood=cosmo_cross_neighborhood(ds_sel,{chan_nbrhood,...
                                        time_nbrhood});
% <@@<

% print how many neighbors features have on average
nbrhood_nfeatures=cellfun(@numel,nbrhood.neighbors);
fprintf('Features have on average %.1f +/- %.1f neighbors\n', ...
            mean(nbrhood_nfeatures), std(nbrhood_nfeatures));

% set the 'measure' variable to a function handle to the
% split-half correlation measure
measure=@cosmo_correlation_measure;


% Define the partitioning scheme using
% cosmo_independent_samples_partitioner.
% Use 'fold_count',1 to use 1 folds,
% and use 'test_ratio',.5 to use 50% of the data for testing (and 50% for
% training) in the single fold.

% >@@>
partitions=cosmo_independent_samples_partitioner(ds,...
                                    'fold_count',1,...
                                    'test_ratio',.5);
% <@@<

% split-half, using oddeven partitioner
measure_args=struct();
measure_args.partitions=partitions;


%% run searchlight
% run the searchlight using the parameters above, and assign the result
% to a varibale 'ds_sl'

% >@@>
ds_sl=cosmo_searchlight(ds_sel,nbrhood,measure,measure_args);
% <@@<

%% visualize timeseries results

% deduce layout from output
layout=cosmo_meeg_find_layout(ds_sl);
fprintf('The output uses layout %s\n', layout.name);

% map ds_sl to a FieldTrip structure. Assign the result to 'sl_ft'
% >@@>
sl_ft=cosmo_map2meeg(ds_sl);
% <@@<

figure();
cfg = [];
cfg.interactive = 'yes';
cfg.zlim=[-1 1];
cfg.layout       = layout;

% show figure with accuracy for each sensor
ft_multiplotER(cfg, sl_ft);

%% visualize topology results
% show figure with topology for 100 before to 400ms after stimulus onset
% in bins of 50 ms
figure();
cfg.xlim=-0.1:0.05:0.4;
ft_topoplotER(cfg, sl_ft);

%% Show citation information
cosmo_check_external('-cite');

