function selected_indices=cosmo_anova_feature_selector(dataset, ratio_to_keep)
% using an anove finds the features that show the most variance between
% classes
%
% selected_indices=cosmo_anova_feature_selector(dataset, ratio_to_keep)
%
% Inputs
%  dataset          struct with .samples and .sa.targets
%  ratio_to_keep    value between 0 and 1
%
% Output
%  selected_indices   feature ids in dataset with most variance between
%                     classes. len(selected_indices) is approximately
%                     equal to ratio_to_keep * size(dataset.samples,2)
%
% NNO Aug 2013



    fs_ds=cosmo_stat(dataset,'F');
    fs=fs_ds.samples;

    % ensure that nan values are not selected by setting them to
    % an impossible low F value
    fs(isnan(fs))=-1;

    % sort by F values, largest first
    [unused, idxs]=sort(fs,'descend');

    % determine features to select
    nfeatures=size(dataset.samples,2);
    n_idxs=round(ratio_to_keep*nfeatures);
    selected_indices=idxs(1:n_idxs);

    % throw an error if any indices with NaN F values
    if any(fs(selected_indices)<0)
        idx=find(fs(selected_indices)<0,1);
        error('Feature %d has NaN Fscore', selected_indices(idx));
    end


