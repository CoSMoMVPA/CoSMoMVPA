function selected_indices=cosmo_anova_feature_selector(dataset, how_many)
% find the features that show the most variance between classes
%
% selected_indices=cosmo_anova_feature_selector(dataset, how_many)
%
% Inputs:
%  dataset          struct with .samples and .sa.targets
%  how_many         value between 0 and 1 keeps how_many*100% features;
%                   values >=1 keeps how_many features
%
% Output:
%  selected_indices   feature ids in dataset with most variance between
%                     classes.
%
% Example:
%     ds=cosmo_synthetic_dataset();
%     disp(size(ds.samples))
%     > [ 6 6 ]
%     cosmo_anova_feature_selector(ds,.45) % find best ~45% of features
%     > [ 2 4 5 ]
%     cosmo_anova_feature_selector(ds,4) % find best 4 features
%     > [ 2 4 5 3 ]
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    fstat=cosmo_stat(dataset,'F');
    fvalues=fstat.samples;

    % ensure that nan values are not selected by setting them to
    % an impossible low F value
    fvalues(isnan(fvalues))=-1;

    % sort by F values, largest first
    [unused, idxs]=sort(fvalues,'descend');

    % determine features to select
    nfeatures=size(dataset.samples,2);

    if how_many>=1
        if round(how_many)~=how_many
            error('how_many>=1 is not an integer');
        elseif how_many>nfeatures
            error('dataset has %d features, cannot return %d',...
                    nfeatures,how_many);
        end
        nkeep=how_many;
    else
        nkeep=round(how_many*nfeatures);
    end

    selected_indices=idxs(1:nkeep);

    % throw an error if any indices with NaN F values
    if any(fvalues(selected_indices)<0)
        idx=find(fvalues(selected_indices)<0,1);
        error('Feature %d has NaN Fscore', selected_indices(idx));
    end


