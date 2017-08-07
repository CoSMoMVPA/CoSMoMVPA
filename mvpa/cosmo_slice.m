function ds=cosmo_slice(ds, to_select, dim, type_or_check)
% Slice a dataset by samples (the default) or features
%
% sliced_ds=cosmo_slice(ds, elements_to_select[, dim][check|'struct'])
%
% Inputs:
%   ds                    One of:
%                         - dataset struct to be sliced, with PxQ field
%                           .samples and optionally fields .fa, .sa and .a.
%                         - PxQ cell
%                         - PxQ logical or numeric array
%   elements_to_select    either a binary mask or a list of indices of
%                         the samples (if dim==1) or features (if dim==2)
%                         to select. If a binary mask then the number of
%                         elements should match the size of ds in the
%                         dim-th dimension.
%   dim                   Slicing dimension: along samples (dim==1) or
%                         features (dim==2). (default: 1).
%   check                 Boolean that indicates that if ds is a dataset,
%                         whether it should be checked for proper
%                         structure. (default: true).
%   'struct'              If provided and ds is a struct, then
%                         all fields of ds, which are assumed to be cell
%                         or arrays,  are sliced.
%
% Output:
%   sliced_ds             - If ds is a cell or array then sliced_ds is
%                           the result of slicing ds along the dim-th
%                           dimension. The result is of size NxQ (if
%                           dim==1) or PxN (if dim==2), where N is the
%                           number of non-zero values in
%                           elements_to_select.
%                         - If ds is a dataset struct then
%                           sliced_ds.samples is the result of slicing
%                           ds.samples.
%                           If present, fields .sa (if dim==1) or
%                           .fa (dim==2) are sliced as well.
%                         - when ds is a struct and the 'struct' option was
%                           given, then all fields in ds are sliced.
%
% Examples:
%     % make a simple dataset
%     ds=struct();
%     ds.samples=reshape(1:12,4,3); % 4 samples, 3 features
%     % sample attributes
%     ds.sa.chunks=[1 1 2 2]';
%     ds.sa.targets=[1 2 1 2]';
%     % feature attributes
%     ds.fa.i=[3 8 13];
%     ds.fa.roi={'vt','loc','v1'};
%     % dataset attributes
%     ds.a.note='an example';
%     % display dataset
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
%     > .a
%     >   .note
%     >     'an example'
%     %
%     % (snippet) select samples (row) in a dataset
%     % ds is a dataset struct
%     sample_ids=[3 2];
%     % select third and second sample (in that order)
%     sliced_ds=cosmo_slice(ds,sample_ids,1);
%     %
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
%     > .a
%     >   .note
%     >     'an example'
%     %
%     % select third and second feature (in that order)
%     sliced_ds=cosmo_slice(ds, [3 2], 2);
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
%     > .a
%     >   .note
%     >     'an example'
%     %
%     % using a logical mask, select features with odd value for .i
%     msk=mod(ds.fa.i,2)==1;
%     disp(msk)
%     > [1 0 1]
%     sliced_ds=cosmo_slice(ds, msk, 2);
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
%     > .a
%     >   .note
%     >     'an example'
%
%     % slice all fields in a struct
%     s=struct();
%     s.a_field=[1 2 3; 4 5 6];
%     s.another_field={'this','is','fun'};
%     cosmo_disp(s);
%     > .a_field
%     >   [ 1         2         3
%     >     4         5         6 ]
%     > .another_field
%     >   { 'this'  'is'  'fun' }
%     %
%     % select first, third, third, and second column (dim=2)
%     t=cosmo_slice(s, [1 3 3 2], 2, 'struct');
%     cosmo_disp(t);
%     > .a_field
%     >   [ 1         3         3         2
%     >     4         6         6         5 ]
%     > .another_field
%     >   { 'this'  'fun'  'fun'  'is' }
%
%
% Notes:
%   - do_check=false may be preferred for slice-intensive operations such
%     as when used in searchlights
%   - this function does not support arrays with more than two dimensions.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % deal with 2, 3, or 4 input arguments
    if nargin<3 || isempty(dim), dim=1; end
    if nargin<4 || isempty(type_or_check), type_or_check=true; end

    if iscell(ds) || isnumeric(ds) || islogical(ds)
        ds=slice_array(ds, to_select, dim, type_or_check);
    elseif isstruct(ds)
        if strcmp(type_or_check,'struct')
            ds=slice_struct(ds, to_select, dim, type_or_check);
        else
            if ~isfield(ds,'samples')
                error(['Expected dataset struct. To slice ordinary '...
                        'structs use "struct" as last argument']);
            end

            if type_or_check
                % check kosherness
                cosmo_check_dataset(ds);
            end

            dim_size=size(ds.samples,dim);

            % slice the samples
            ds.samples=slice_array(ds.samples,to_select,dim,type_or_check);

            % now deal with either feature or sample attributes
            attr_fns={'sa','fa'};
            attr_fn=attr_fns{dim}; % fieldname of attribute to slice

            if isfield(ds, attr_fn)
                ds.(attr_fn)=slice_struct(ds.(attr_fn),to_select,...
                                               dim,type_or_check,dim_size);
            end
        end
    else
        error('Illegal input: expected cell, array or struct');
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % helper functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function y=slice_struct(x, to_select, dim, do_check, expected_size)
        if nargin<5, expected_size=NaN; end

        y=struct();
        fns=fieldnames(x);
        for k=1:numel(fns)
            fn=fns{k};
            v=x.(fn);

            v_size=size(v,dim);

            % ensure all input sizes are the same
            if isnan(expected_size)
                expected_size=v_size;
            elseif v_size~=expected_size
                error(['Size mismatch for %s: expected %d but found %d',...
                        ' elements in dimension %d'],...
                                fn, v_size, expected_size, dim);
            end

            y.(fn)=slice_array(v, to_select, dim, do_check);
        end


    function y=slice_array(x, to_select, dim, do_check)
        if do_check
            check_size(x, to_select, dim);
            if ~isscalar(dim) || ~isnumeric(dim)
                error('dim must be 1 or 2');
            end
        end

        if dim==1
            y=x(to_select,:);
        elseif dim==2
            y=x(:,to_select);
        else
            error('dim must be 1 or 2');
        end


    function check_size(x, to_select, dim)
        if islogical(to_select) && ...
                    size(x, dim)~=numel(to_select)
            % be a bit more strict than matlab - binary array must have
            % exactly the correct size
            error('Logical mask should have %d elements, found %d', ...
                    size(x, dim), numel(to_select));
        end

        if numel(size(x))~=2
            error('Only 2D arrays are allowed');
        end

        if sum(size(to_select)>1)>1
            error('elements to select should be in vector');
        end

