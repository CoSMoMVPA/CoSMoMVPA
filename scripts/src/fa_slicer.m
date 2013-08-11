function dataset = fa_slicer(dataset, feature_indices)
    %%
    % First slice the data
    dataset.samples = dataset.samples(:,feature_indices);

    %% Now change all of the sample attributes
    fn = fieldnames(dataset.fa);
    nfields = length(fn);
    for i = 1:nfields
        dataset.fa.(fn{i}) = dataset.fa.(fn{i})(sample_indices);
    end

end

