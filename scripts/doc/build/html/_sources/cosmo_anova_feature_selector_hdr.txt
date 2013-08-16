.. cosmo_anova_feature_selector_hdr

cosmo anova feature selector hdr
--------------------------------
.. code-block:: matlab

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