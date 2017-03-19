%% MEEG time generalization in a region (in space-time) of interest
%
% This example shows MVPA analyses performed on MEEG data.
%
% The input dataset involved a paradigm where a participant saw
% images of six object categories.
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

% convert to cosmomvpa struct and show the dataset
ds=cosmo_meeg_dataset(data_tl);
cosmo_disp(ds);


%%

% set the targets (trial condition)
% Hint: use the first column from ds.sa.trialinfo
% >@@>
ds.sa.targets=ds.sa.trialinfo(:,1); % 6 categories
% <@@<

% set the chunks (independent measurements)
% all trials are here considered to be independent
% >@@>
nsamples=size(ds.samples,1);
ds.sa.chunks=(1:nsamples)';
% <@@<

% in addition give a label to each trial
index2label={'body','car','face','flower','insect','scene'};
ds.sa.labels=cellfun(@(x)index2label(x),num2cell(ds.sa.targets));

% just to check everything is ok
cosmo_check_dataset(ds);

%% Select subset of sensors and time points

% Select posterior gradiometers
sensor_posterior_planar={'MEG1632', 'MEG1642', 'MEG1732', 'MEG1842', ...
                        'MEG1912', 'MEG1922', 'MEG1942', 'MEG2232', ...
                        'MEG2312', 'MEG2322', 'MEG2342', 'MEG2432', ...
                        'MEG2442', 'MEG2512', 'MEG2532',...
                        'MEG1633', 'MEG1643', 'MEG1733', 'MEG1843', ...
                        'MEG1913', 'MEG1923', 'MEG1943', 'MEG2233', ...
                        'MEG2313', 'MEG2323', 'MEG2343', 'MEG2433', ...
                        'MEG2443', 'MEG2513', 'MEG2533'};

msk=cosmo_dim_match(ds,'chan',sensor_posterior_planar,...
                        'time',@(t)t>=0 & t<=.3);

ds_sel=cosmo_slice(ds,msk,2);
ds_sel=cosmo_dim_prune(ds_sel);

% Reduce the number of chunks to have only two chunks
% Hint: use cosmo_chunkize
% >@@>
ds_sel.sa.chunks=cosmo_chunkize(ds_sel,2);
% <@@<

% Now use cosmo_dim_transpose to make 'time' a sample dimension
% Hint: the third argument to cosmo_dim_transpose must be 1, because
% time now describes the first (sample) dimension in .samples
% >@@>
ds_tr=cosmo_dim_transpose(ds_sel,'time',1);
% <@@<



% Set the measure to be a function handle to
% cosmo_dim_generalization_measure
measure=@cosmo_dim_generalization_measure;

% Set measure arguments
measure_args=struct();

% Use the measure with the following arugments:
% - measure: @cosmo_crossvalidation_measure
% - classifier: @cosmo_classify_lda
% - dimension: 'time'
measure_args.measure=@cosmo_crossvalidation_measure;
measure_args.classifier=@cosmo_classify_lda;
measure_args.dimension='time';

% Now apply the measure to the dataset, and store the output in a variable
% 'result'
result=measure(ds_tr,measure_args);

%% Visualize results

% Unflatten the dataset using cosmo_unflatten, and assign the result
% to three variables: data, labels and values
% Hint: the second argument to cosmo_unflatten must be 1

% >@@>
[data,labels,values]=cosmo_unflatten(result,1);
% <@@<

% Visualize the data matrix using imagesc
% >@@>
imagesc(data,[0 0.5]);
% <@@<
colorbar();

% Show labels
nticks=5;
ytick=round(linspace(1, numel(values{1}), nticks));
ylabel(strrep(labels{1},'_',' '));
set(gca,'Ytick',ytick,'YTickLabel',values{1}(ytick));

xtick=round(linspace(1, numel(values{2}), nticks));
xlabel(strrep(labels{2},'_',' '));
set(gca,'Xtick',xtick,'XTickLabel',values{2}(xtick));
