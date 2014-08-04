function ds_splits=cosmo_split(ds, split_by, dim)
% splits a dataset by unique values in (a) sample or feature attribute(s).
%
% cosmo_split(ds, split_by[, dim])
%
% Inputs:
%   ds          dataset struct
%   split_by    fieldname for the sample (if dim==1) or feature (if dim==2)
%               attribute by which the dataset is split.
%               It can also be a cell with fieldnames, in which case the
%               dataset is split by the set of combinations from these
%               fieldnames.
%   dim         1 (split by samples; default) or 2 (split by features).
%
% Returns:
%   ds_splits   1xP cell, if there are P unique values for the (set of)
%               attribute(s) indicated by split_by and dim.
%
% Note:
%   - This function is like the inverse of cosmo_stack;
%
%       >> ds_splits=cosmo_split(ds, split_by, dim),
%
%   - produces output (i.e., does not throw an error), then using
%
%       >> ds_humpty_dumpty=cosmo_stack(ds_splits,dim)
%
%   - means that ds and ds_humpty_dumpty contain the same data, except that
%     the order of the data (in the rows [columns] of .samples, or
%     .sa [.fa]) may be different if dim==1 [dim==2].
%
% Examples:
%   % ds is a dataset struct
%   % split by targets sample attribute. If there are N unique targets,
%   % the splits output has N elements
%   >> splits=cosmo_split(ds,'targets')
%
%   % this is equivalent to the previous example, but the dimension is set
%   % explicitly
%   >> splits=cosmo_split(ds,{'targets'},1)
%
%   % split by 'chunks' sample attribute
%   >> splits=cosmo_split(ds,'targets')
%
%   % split by 'chunks' and 'targets' sample attributes.
%   >> splits=cosmo_split(ds,{'targets','chunks'})
%
%   % split by 'time' feature attribute (e.g. when ds is an MEEG dataset).
%   >> splits=cosmo_split(ds,'time',2)
%
%   % split by 'time' and 'chan' feature attributes.
%   >> splits=cosmo_split(ds,{'time','chan'},2)
%
% See also: cosmo_stack, cosmo_slice
%
% NNO Sep 2013

    % set default dim & check input
    if nargin<3 || isempty(dim)
        dim=1;
    elseif dim~=1 && dim~=2
        error('dim should be 1 or 2');
    end

    % undocumented feature: support arrays as well
    is_ds=isstruct(ds) && isfield(ds, 'samples');
    if is_ds
        size_dim=size(ds.samples,dim);
    elseif isnumeric(ds) || islogical(ds)
        size_dim=size(ds,dim);
    else
        error('illegal input: expected struct or array');
    end

    % empty split, so return just the dataset itself
    if isempty(split_by)
        ds_splits={ds};
        return
    end

    % cell input, one or more fieldnames to split by
    if iscell(split_by)
        if numel(split_by)>1
            % delegate to helper function
            ds_splits=split_recursively(ds, split_by, dim);
            return
        else
            % single fieldname, extract it from cell
            split_by=split_by{1};
        end
    end


    if is_ds
        attrs_fns={'sa','fa'};
        attrs_fn=attrs_fns{dim};

        % ensure the field is there
        if ~isfield(ds, attrs_fn) || ~isfield(ds.(attrs_fn), split_by)
            error('missing field .%s.%s', attrs_fn, split_by);
        end

        values=ds.(attrs_fn).(split_by);
    else
        % split_by should be an array with the values to split on
        values=split_by;
    end

    is_vector=sum(size(values)>1)<=1;

    % ensure splitting based on values in a vector
    if ~is_vector || numel(values)~=size_dim
        if is_ds
            selector_str=sprintf('field %s.%s', attrs_fn, split_by);
        else
            selector_str='split_by';
        end

        error('%s must be vector with length %d', ...
                    selector_str,size_dim);
    end

    if numel(values)==1
        % singleton element - little optimization
        ds_splits={ds};
    else
        % get unique values
        split_values=unique(values);
        nsplits=numel(split_values);

        % allocate space for output
        ds_splits=cell(1,nsplits);

        % slice for each unique value seperately
        for k=1:nsplits
            ds_splits{k}=cosmo_slice(ds, values==split_values(k), ...
                                                        dim, false);
        end
    end

function ds_splits=split_recursively(ds, split_by, dim)
    % helper function to be used with >1 fieldname to split by

    me=str2func(mfilename()); % make imune to renaming

    % split by first fieldname
    split_head=me(ds, split_by{1}, dim);

    % allocate space for remaining splits
    nhead=numel(split_head);
    split_all=cell(1,nhead);

    % remaining fieldnames
    split_by_tail=split_by(2:end);

    % split each of them
    for k=1:nhead
        split_all{k}=me(split_head{k}, split_by_tail, dim);
    end

    % join results
    ds_splits=[split_all{:}];

