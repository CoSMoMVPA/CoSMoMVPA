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
%   ds_splits   1xP cell, if there are P unique values for the (set of
%               attribute(s) indicated by split_by and dim.
%
% Note:
%   this function is like the inverse of cosmo_stack, in the sense that if
%       ds_splits=cosmo_split(ds, split_by, dim),
%   produces output (i.e., does not throw an error), then using
%       ds_humpty_dumpty=cosmo_stack(ds_splits,dim)
%   means that ds and ds_humpty_dumpty contain the same data, except that 
%   the order of the data (in the rows [columns] of .samples, or .sa [.fa])  
%   may be different if dim==1 [dim==2].
%
% See also: cosmo_stack
%
% NNO Sep 2013

% set default dim
if nargin<3 || isempty(dim), dim=1; end

is_ds=isstruct(ds) && isfield(ds, 'samples');
if is_ds
    size_dim=size(ds.samples,dim);
elseif isnumeric(ds) || islogical(ds)
    size_dim=size(ds,dim);
else
    error('illegal input: expected struct or array');
end

if iscell(split_by)
    ndim=numel(split_by);

    if ndim>1
        % more than one fieldname to split; use recursion
        
        me=str2func(mfilename()); % make imune to renaming
        
        % split by first fieldname
        split_head=me(ds, split_by{1}, dim);
        nhead=numel(split_head);
        
        % allocate space for remaining splits
        split_all=cell(1,nhead);
        
        % remaining fieldnames 
        split_by_tail={split_by{2:end}};
        
        % split each of them
        for k=1:nhead
            split_all{k}=me(split_head{k}, split_by_tail, dim);
        end
        
        % join results
        ds_splits=[split_all{:}];
        return
    end
   
    % just one field, get it out and continue
    split_by=split_by{1};
end

if all(dim~=[1 2]), error('dim should be 1 or 2'); end

if is_ds
    attrs_fns={'sa','fa'};
    attrs_fn=attrs_fns{dim};

    % ensure the field is there
    if ~isfield(ds, attrs_fn) || ~isfield(ds.(attrs_fn), split_by)
        error('missing field .%s.%s', attrs_fn, split_by); 
    end
    
    selector_str=sprintf('field %s.%s', attrs_fn, split_by);

    values=ds.(attrs_fn).(split_by);
else
    values=split_by;
    selector_str='split_by';
end
    
if sum(size(values)>1)>1 || numel(values)~=size_dim
    error('%s must be vector with length %d', ...
                selector_str,size_dim);
end

if numel(values)==1
    % singleton element - little optimization
    ds_splits={ds};
else
    split_values=unique(values);
    nsplits=numel(split_values);

    ds_splits=cell(1,nsplits);
    for k=1:nsplits
        ds_splits{k}=cosmo_slice(ds, values==split_values(k), dim, false);
    end
end
