.. solution_1b

Sample attributes slicer
========================


.. code-block:: matlab

    function dataset = sa_slicer(dataset, sample_indices)
        %%
        % First slice the data
        dataset.samples = dataset.samples(sample_indices,:);

        %% Now change all of the sample attributes
        fn = fieldnames(dataset.sa);
        nfields = length(fn);
        for i = 1:nfields
            dataset.sa.(fn{i}) = dataset.sa.(fn{i})(sample_indices);
        end

        %% Finally change the dimensions in the nifti header
        dataset.a.imghdr.hdr.dime.dim(1,5) = length(sample_indices);
    end



