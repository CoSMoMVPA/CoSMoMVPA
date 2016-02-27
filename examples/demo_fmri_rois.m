%% Demo: fMRI Region-Of-Interest (ROI) analyses
%
% The data used here is available from http://cosmomvpa.org/datadb.zip
%
% It is based on the following work:
% * Connolly et al (2012), Representation of biological classes in the human
%   brain. Journal of Neuroscience, doi 10.1523/JNEUROSCI.5547-11.2012
%
% Six categories (monkey, lemur, mallard, warbler, ladybug, lunamoth)
% during ten runs in an fMRI study. Using the General Linear Model response
% were estimated for each category in each run, resulting in 6*10=60
% t-values.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

%% Set data paths
% The function cosmo_config() returns a struct containing paths to tutorial
% data. (Alternatively the paths can be set manually without using
% cosmo_config.)
config=cosmo_config();
study_path=fullfile(config.tutorial_data_path,'ak6');
output_path=config.output_data_path;

readme_fn=fullfile(study_path,'README');
cosmo_type(readme_fn);

% reset citation list
cosmo_check_external('-tic');

%% Example 1: split-half correlation measure (Haxby 2001-style)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subject_id='s01';
mask_label='ev_mask';
data_path=fullfile(study_path,subject_id); % data from subject s01

% Define data locations and load data from even and odd runs
mask_fn=fullfile(data_path, [mask_label '.nii']); % whole brain

data_odd_fn=fullfile(data_path,'glm_T_stats_odd.nii');
ds_odd=cosmo_fmri_dataset(data_odd_fn,'mask',mask_fn,...
                            'targets',1:6,'chunks',1);


data_even_fn=fullfile(data_path,'glm_T_stats_even.nii');
ds_even=cosmo_fmri_dataset(data_even_fn,'mask',mask_fn,...
                            'targets',1:6,'chunks',2);

% Combine even and odd runs
ds_odd_even=cosmo_stack({ds_odd, ds_even});

% remove constant features
ds_odd_even=cosmo_remove_useless_data(ds_odd_even);

% print dataset
fprintf('Dataset input:\n');
cosmo_disp(ds_odd_even);

% compute correlations
ds_corr=cosmo_correlation_measure(ds_odd_even);

% show result
fprintf(['Average correlation difference between matching and '...
            'non-matching categories in %s for %s is %.3f\n'],...
            mask_label, subject_id, ds_corr.samples);


%% Example 2: split-half correlation measure with group analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subject_ids={'s01','s02','s03','s04','s05','s06','s07','s08'};
nsubjects=numel(subject_ids);

mask_label='vt_mask';

ds_corrs=cell(nsubjects,1); % allocate space for output
for subject_num=1:nsubjects
    subject_id=subject_ids{subject_num};

    % Code from here is pretty much identical to that above >>>

    % set path for this subject
    data_path=fullfile(study_path,subject_id);

    % Define data locations and load data from even and odd runs
    mask_fn=fullfile(data_path, [mask_label '.nii']); % whole brain

    data_odd_fn=fullfile(data_path,'glm_T_stats_odd.nii');
    ds_odd=cosmo_fmri_dataset(data_odd_fn,'mask',mask_fn,...
                                'targets',1:6,'chunks',1);


    data_even_fn=fullfile(data_path,'glm_T_stats_even.nii');
    ds_even=cosmo_fmri_dataset(data_even_fn,'mask',mask_fn,...
                                'targets',1:6,'chunks',2);

    % Combine even and odd runs
    ds_odd_even=cosmo_stack({ds_odd, ds_even});

    % remove constant features
    ds_odd_even=cosmo_remove_useless_data(ds_odd_even);

    ds_corr=cosmo_correlation_measure(ds_odd_even);

    % <<< identical up to here

    % set targets and chunks for the output, so that cosmo_stat can be used
    % below
    ds_corr.sa.targets=1;
    ds_corr.sa.chunks=subject_num;

    ds_corrs{subject_num}=ds_corr;
end

% combine the data from all subjects
ds_all=cosmo_stack(ds_corrs);

%%
samples=ds_all.samples; % get the correlations for all subjects

% run one-sample t-test again zero

% Using cosmo_stats
ds_t=cosmo_stat(ds_all,'t');     % t-test against zero
ds_p=cosmo_stat(ds_all,'t','p'); % convert to p-value

fprintf(['correlation difference in %s at group level: '...
           '%.3f +/- %.3f, %s=%.3f, p=%.5f (using cosmo_stat)\n'],...
            mask_label,mean(samples),std(samples),...
            ds_t.sa.stats{1},ds_t.samples,ds_p.samples);

% Using matlab's stat toolbox (if present)
if cosmo_check_external('@stats',false)
    [h,p,ci,stats]=ttest(samples);
    fprintf(['Correlation difference in %s at group level: '...
            '%.3f +/- %.3f, t_%d=%.3f, p=%.5f (using matlab stats '...
            'toolbox)\n'],...
            mask_label,mean(samples),std(samples),stats.df,stats.tstat,p);
else
    fprintf('Matlab stats toolbox not found\n');
end


%% Example 3: comparison of four classifiers in two regions of interest
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');
data_fn=fullfile(data_path,'glm_T_stats_perrun.nii');

% Define classifiers and mask labels
classifiers={@cosmo_classify_nn,...
             @cosmo_classify_naive_bayes,...
             @cosmo_classify_lda};

% Use svm classifiers, if present
svm_name2func=struct();
svm_name2func.matlabsvm=@cosmo_classify_matlabsvm;
svm_name2func.libsvm=@cosmo_classify_libsvm;
svm_name2func.svm=@cosmo_classify_svm;
svm_names=fieldnames(svm_name2func);
for k=1:numel(svm_names)
    svm_name=svm_names{k};
    if cosmo_check_external(svm_name,false)
        classifiers{end+1}=svm_name2func.(svm_name);
    else
        warning('Classifier %s skipped because not available', svm_name);
    end
end

mask_labels={'vt_mask','ev_mask'};

%
nclassifiers=numel(classifiers);
nmasks=numel(mask_labels);

labels={'monkey', 'lemur', 'mallard', 'warbler', 'ladybug', 'lunamoth'};

% little helper function to replace underscores by spaces
underscore2space=@(x) strrep(x,'_',' ');

for j=1:nmasks
    mask_label=mask_labels{j};
    mask_fn=fullfile(data_path,[mask_label '.nii']);
    ds=cosmo_fmri_dataset(data_fn,'mask',mask_fn,...
                        'targets',repmat(1:6,1,10),...
                        'chunks',floor(((1:60)-1)/6)+1);

    % remove constant features
    ds=cosmo_remove_useless_data(ds);

    % print dataset
    fprintf('Dataset input:\n');
    cosmo_disp(ds);

    % Define partitions
    partitions=cosmo_nfold_partitioner(ds);

    % print dataset
    fprintf('Partitions:\n');
    cosmo_disp(partitions);

    % show result for each classifier
    for k=1:nclassifiers
        classifier=classifiers{k};
        [pred,accuracy]=cosmo_crossvalidate(ds, classifier, partitions);

        confusion_matrix=cosmo_confusion_matrix(ds.sa.targets,pred);
        figure
        imagesc(confusion_matrix,[0 10])
        cfy_label=underscore2space(func2str(classifier));
        title_=sprintf('%s using %s: accuracy=%.3f', ...
                        underscore2space(mask_label), cfy_label, accuracy);
        title(title_)
        set(gca,'XTickLabel',labels);
        set(gca,'YTickLabel',labels);
        ylabel('target');
        xlabel('predicted');
    end
end

%% Show citation information
cosmo_check_external('-cite');
