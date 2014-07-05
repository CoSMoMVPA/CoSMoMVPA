function ds=cosmo_dataset_slice_fa(ds, to_select)
% Slice a dataset by features (columns)
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
%     >     [  3
%     >        8
%     >       13 ]
%     >   .roi
%     >     { 'vt'  'loc'  'v1' }
%     %
%     % select third and second features (in that order)
%     sliced_ds=cosmo_dataset_slice_fa(ds, [3 2]);
%     cosmo_disp(sliced_ds);
%     > .samples
%     >   [  9         5
%     >     10         6
%     >     11         7
%     >     12         8 ]
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
%     >     [ 13         8 ]
%     >   .roi
%     >     { 'v1'  'loc' }
%     %
%     % using a logical mask, select features with odd value for .i
%     msk=mod(ds.fa.i,2)==1;
%     disp(msk)
%     > [1 0 1]
%     sliced_ds=cosmo_dataset_slice_fa(ds, msk);
%     cosmo_disp(sliced_ds);
%     > .samples
%     >   [ 1         9
%     >     2        10
%     >     3        11
%     >     4        12 ]
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
%     >     [ 3        13 ]
%     >   .roi
%     >     { 'vt'  'v1' }
%
% Note:
%   - this function is intended as an exercise. For a more powerful 
%     implementation that deals with cell inputs correctly,
%     consider using comso_slice(dataset, to_select, 2).
%      
% See also: cosmo_slice, cosmo_dataset_slice_fa
    
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