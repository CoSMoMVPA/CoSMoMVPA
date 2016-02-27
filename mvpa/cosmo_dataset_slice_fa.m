function ds=cosmo_dataset_slice_fa(ds, to_select)
% Slice a dataset by features (columns) [deprecated]
%
% sliced_ds=cosmo_dataset_slice_fa(ds, to_select)
%
% Input:
%   ds          a dataset struct with fields .samples (MxN for M samples
%               and N features), and optionally
%               features attributes in ds.fa, each ?xN)
%   to_select:  Either a boolean mask, or a vector with indices, indicating
%               which features to select in ds
%
% Returns:
%   sliced_ds   a dataset struct with the same fields as the input, but
%               with the selected samples in .samples (MxP, if to_select
%               selected P values) and the selected features in ds.fa
%
% Note:
%   - This function was, in 2013, intended as an exercise.
%   - This function is deprecated and will be removed in the future;
%     it is strongly recommended to use:
%           comso_slice(dataset, to_select, 2).
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    cosmo_warning(['%s is deprecated and will be removed in the future;'...
                ' use cosmo_slice(...,...,2) instead'],...
                  mfilename());

    % First slice the features array by columns

    % >@@>
    ds.samples=ds.samples(:,to_select);
    % <@@<

    %%
    %   If there is a field .fa, go through each attribute and slice it.
    %
    %   Hint: we used the matlab function 'fieldnames' to list the fields
    %   in dataset.fa


    if isfield(ds,'fa')
        % >@@>
        fns = fieldnames(ds.fa);
        n = numel(fns);

        for k=1:n
            fn = fns{k};
            fa = ds.fa.(fn);
            ds.fa.(fn)=fa(:,to_select);
        end
        % <@@<
    end
