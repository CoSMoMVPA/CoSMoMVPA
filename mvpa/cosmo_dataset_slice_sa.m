function ds=cosmo_dataset_slice_sa(ds, to_select)
% Slice a dataset by samples (rows)
%
% sliced_ds=cosmo_dataset_slice_sa(ds, to_select)
%
% Input:
%   ds          a dataset struct with fields .samples (MxN for M samples
%               and N features), and optionally
%               sample attributes in ds.fa, each Nx>)
%   to_select:  Either a boolean mask, or a vector with indices, indicating
%               which samples to select in ds
%
% Returns:
%   sliced_ds   a dataset struct with the same fields as the input, but
%               with the selected samples in .samples (PxN, if to_select
%               selected O values) and the selected features in ds.sa
%
% Examples:
%     ds=struct();
%     ds.samples=reshape(1:12,4,3); % 4 samples, 3 features
%     ds.sa.chunks=[1 1 2 2]';
%     ds.sa.targets=[1 2 1 2]';
%     ds.fa.i=[3 8 13];
%     ds.fa.roi={'vt','loc','v1'};
%     cosmo_disp(ds);
%     > .samples
%     >   [ 1         5         9
%     >     2         6        10
%     >     3         7        11
%     >     4         8        12 ]
%     > .sa
%     >   .chunks
%     >     [ 1
%     >       1
%     >       2
%     >       2 ]
%     >   .targets
%     >     [ 1
%     >       2
%     >       1
%     >       2 ]
%     > .fa
%     >   .i
%     >     [ 3         8        13 ]
%     >   .roi
%     >     { 'vt'  'loc'  'v1' }
%     %
%     % select third and second samples (in that order)
%     sliced_ds=cosmo_dataset_slice_sa(ds, [3 2]);
%     cosmo_disp(sliced_ds);
%     > .samples
%     >   [ 3         7        11
%     >     2         6        10 ]
%     > .sa
%     >   .chunks
%     >     [ 2
%     >       1 ]
%     >   .targets
%     >     [ 1
%     >       2 ]
%     > .fa
%     >   .i
%     >     [ 3         8        13 ]
%     >   .roi
%     >     { 'vt'  'loc'  'v1' }
%     %
%     % using a logical mask, select samples with odd value for .targets
%     msk=mod(ds.sa.targets,2)==1;
%     disp(msk)
%     >      1
%     >      0
%     >      1
%     >      0
%     sliced_ds=cosmo_dataset_slice_sa(ds, msk);
%     cosmo_disp(sliced_ds);
%     > .samples
%     >   [ 1         5         9
%     >     3         7        11 ]
%     > .sa
%     >   .chunks
%     >     [ 1
%     >       2 ]
%     >   .targets
%     >     [ 1
%     >       1 ]
%     > .fa
%     >   .i
%     >     [ 3         8        13 ]
%     >   .roi
%     >     { 'vt'  'loc'  'v1' }
%
% Note:
%   - this function is intended as an exercise. For a more powerful
%     implementation that deals with cell inputs correctly,
%     consider using comso_slice(dataset, to_select, 1).
%
% See also: cosmo_slice, cosmo_dataset_slice_fa

    % First slice the features array by columns

    % >@@>
    ds.samples=ds.samples(to_select,:);
    % <@@<

    %%
    %   If there is a field .sa, go through each attribute and slice it.
    %
    %   Hint: we used the matlab function 'fieldnames' to list the fields
    %   in dataset.fa


    if isfield(ds,'sa')
        % >@@>
        fns = fieldnames(ds.sa);
        n = numel(fns);

        for k=1:n
            fn = fns{k};
            sa = ds.sa.(fn);
            ds.sa.(fn)=sa(to_select,:);
        end
        % <@@<
    end
