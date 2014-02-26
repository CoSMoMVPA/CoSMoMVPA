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
    
    
    
    fs=cosmo_stat(dataset,'F');
    
    [unused, idxs]=sort(fs.samples,'descend');
    nfeatures=size(dataset.samples,2);
    n_idxs=round(ratio_to_keep*nfeatures);
    selected_indices=idxs(1:n_idxs);
    
    if any(isnan(fs(selected_indices)))
        idx=find(isnan(fs(selected_indices)));
        error('Feature %d has NaN Fscore', selected_indices(idx));
    end
    
    