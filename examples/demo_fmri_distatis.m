%% Demo: DISTATIS
%
% The data used here is available from http://cosmomvpa.org/datadb.zip
%
% It is based on the following work:
% * Connolly et al (2012), Representation of biological classes in the human
%   brain. Journal of Neuroscience, doi 10.1523/JNEUROSCI.5547-11.2012
%
% Six categories (monkey, lemur, mallard, warbler, ladybug, lunamoth)
% during ten runs in an fMRI study.
%
% This example shows the application of DISTATIS, which tries to find an
% optimal 'compromise' dissimilarity matrix across a set of observations
% (participants)
%
% Reference:
%   - Abdi, H., Valentin, D., O?Toole, A. J., & Edelman, B. (2005).
%     DISTATIS: The analysis of multiple distance matrices. In
%     Proceedings of the IEEE Computer Society: International conference
%     on computer vision and pattern recognition, San Diego, CA, USA
%     (pp. 42?47).
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

%% Preprocessing for DISTATIS: RSM analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subject_ids={'s01','s02','s03','s04','s05','s06','s07','s08'};
nsubjects=numel(subject_ids);

mask_label='vt_mask';

ds_rsms=cell(nsubjects,1); % allocate space for output
for subject_num=1:nsubjects
    subject_id=subject_ids{subject_num};

    % Code from here is pretty much identical to that above >>>

    % set path for this subject
    data_path=fullfile(study_path,subject_id);

    % Define data locations and load data from even and odd runs
    mask_fn=fullfile(data_path, [mask_label '.nii']); % vt mask

    % Use odd runs only
    data_fn=fullfile(data_path,'glm_T_stats_odd.nii');
    ds=cosmo_fmri_dataset(data_fn,'mask',mask_fn,...
                            'targets',1:6,'chunks',1);

    ds_rsm=cosmo_dissimilarity_matrix_measure(ds);

    % set chunks (one chunk per subject)
    ds_rsm.sa.chunks=subject_num*ones(size(ds_rsm.samples,1),1);
    ds_rsms{subject_num}=ds_rsm;
end

% combine data from all subjects
all_ds=cosmo_stack(ds_rsms);

%% Run DISTATIS
distatis=cosmo_distatis(all_ds);

%% show comprimise distance matrix
[compromise_matrix,dim_labels,values]=cosmo_unflatten(distatis,1);

labels={'monkey', 'lemur', 'mallard', 'warbler', 'ladybug', 'lunamoth'};
figure();
imagesc(compromise_matrix)
title('DSM');
set(gca,'YTickLabel',labels);
set(gca,'XTickLabel',labels);
ylabel(dim_labels{1});
xlabel(dim_labels{2});
colorbar

% skip if stats toolbox is not present
if cosmo_check_external('@stats',false)
    figure();
    hclus = linkage(compromise_matrix);
    dendrogram(hclus,'labels',labels,'orientation','left');
    title('dendrogram');

    figure();
    F = cmdscale(squareform(compromise_matrix));
    text(F(:,1), F(:,2), labels);
    title('2D MDS plot');
    mx = max(abs(F(:)));
    xlim([-mx mx]); ylim([-mx mx]);
end


%% show citation information
cosmo_check_external('-cite');
