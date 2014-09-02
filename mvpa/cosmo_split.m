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
% Examples:
%     ds=cosmo_synthetic_dataset();
%     %
%     % split by targets
%     splits=cosmo_split(ds,'targets');
%     cosmo_disp(splits{2}.sa);
%     > .targets
%     >   [ 2
%     >     2
%     >     2 ]
%     > .chunks
%     >   [ 1
%     >     2
%     >     3 ]
%     %
%     % split by chunks
%     splits=cosmo_split(ds,'chunks');
%     cosmo_disp(splits{3}.sa);
%     > .targets
%     >   [ 1
%     >     2 ]
%     > .chunks
%     >   [ 3
%     >     3 ]
%     %
%     % split by chunks and targets
%     splits=cosmo_split(ds,{'chunks','targets'});
%     cosmo_disp(splits{5}.sa);
%     > .targets
%     >   [ 1 ]
%     > .chunks
%     >   [ 3 ]
%
%     % take an MEEG time-freq dataset, and split by time and channel
%     ds=cosmo_synthetic_dataset('type','timefreq','size','big');
%     %
%     % dataset has 11 channels, 7 frequencies and 5 time points
%     cosmo_disp(ds.fa)
%     > .chan
%     >   [ 1         2         3  ...  304       305       306 ]@1x10710
%     > .freq
%     >   [ 1         1         1  ...  7         7         7 ]@1x10710
%     > .time
%     >   [ 1         1         1  ...  5         5         5 ]@1x10710
%     %
%     % split by time and frequency. Since splitting is done on the feature
%     % dimension, the third argument (with value 2) is mandatory
%     splits=cosmo_split(ds,{'time','freq'},2);
%     % there are 7 * 5 = 35 splits, each with 11 features
%     numel(splits)
%     > 35
%     cosmo_disp(cellfun(@(x) size(x.samples,2),splits))
%     > [ 306       306       306  ...  306       306       306 ]@1x35
%     cosmo_disp(splits{18}.fa)
%     > .chan
%     >   [ 1         2         3  ...  304       305       306 ]@1x306
%     > .freq
%     >   [ 4         4         4  ...  4         4         4 ]@1x306
%     > .time
%     >   [ 3         3         3  ...  3         3         3 ]@1x306
%     %
%     % using cosmo_stack brings the split elements together again
%     humpty_dumpty=cosmo_stack(splits,2);
%     cosmo_disp(humpty_dumpty.fa)
%     > .chan
%     >   [ 1         2         3  ...  304       305       306 ]@1x10710
%     > .freq
%     >   [ 1         1         1  ...  7         7         7 ]@1x10710
%     > .time
%     >   [ 1         1         1  ...  5         5         5 ]@1x10710
%
% Note:
%   - This function is like the inverse of cosmo_stack; if
%
%       >> ds_splits=cosmo_split(ds, split_by, dim),
%
%     produces output (i.e., does not throw an error), then using
%
%       >> ds_humpty_dumpty=cosmo_stack(ds_splits,dim)
%
%     means that ds and ds_humpty_dumpty contain the same data, except that
%     the order of the data (in the rows [columns] of .samples, or
%     .sa [.fa]) may be different if dim==1 [dim==2].
%
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

    size_dim=size(ds.samples,dim);

    % empty split, so return just the dataset itself
    if isempty(split_by)
        ds_splits={ds};
        return
    end

    if ischar(split_by)
        split_by={split_by};
    elseif ~iscellstr(split_by)
        error('split_by must be string or cell of strings');
    end


    % delegate to helper function
    ds_splits=split_recursively(ds, split_by, dim);


function ds_splits=split_single(ds, split_by, dim)
    attrs_fns={'sa','fa'};
    attrs_fn=attrs_fns{dim};

    % ensure the field is there
    if ~isfield(ds, attrs_fn) || ~isfield(ds.(attrs_fn), split_by)
        error('missing field .%s.%s', attrs_fn, split_by);
    end

    values=ds.(attrs_fn).(split_by);

    % ensure splitting based on values in a vector
    if ~isvector(values) || numel(values)~=size(ds.samples,dim);
        selector_str=sprintf('field %s.%s', attrs_fn, split_by);
        error('%s must be vector with length %d', ...
                    selector_str,size_dim);
    end

    % get unique values
    split_values=unique(values);
    nsplits=numel(split_values);

    if nsplits==1
        % singleton element - little optimization
        ds_splits={ds};
    else
        % allocate space for output
        ds_splits=cell(1,nsplits);

        % slice for each unique value seperately
        for k=1:nsplits
            ds_splits{k}=cosmo_slice(ds, values==split_values(k), ...
                                                        dim, false);
        end
    end

function ds_splits=split_recursively(ds, split_by, dim)
    % split by first fieldname
    split_head=split_single(ds, split_by{1}, dim);

    if numel(split_by)==1
        ds_splits=split_head;
        return;
    end

    % allocate space for remaining splits
    nhead=numel(split_head);
    split_all=cell(1,nhead);

    % remaining fieldnames
    split_by_tail=split_by(2:end);

    % split each of them
    for k=1:nhead
        split_all{k}=split_recursively(split_head{k}, split_by_tail, dim);
    end

    % join results
    ds_splits=[split_all{:}];

