function ds_pruned=cosmo_dim_prune(ds, labels)

cosmo_check_dataset(ds);

if nargin<2
    labels=ds.a.fdim.labels;
elseif ischar(labels)
    labels={labels};
end


if ~iscell(labels) && all(cellfun(@ischar,labels))
    error('expected cell with labels, or single string');
end

% removes the values in ds.a.fdim that are not used

nlabels=numel(labels);
ds_pruned=ds; % output

for k=1:nlabels
    label=labels{k};
    dim=find(cosmo_match(ds.a.fdim.labels, label));

    if numel(dim)~=1, error('Illegal label %s', label); end

    values=ds.a.fdim.values{dim};
    fa=ds.fa.(label);
    [unq_idxs,unused,map_idxs]=unique(fa);

    ds_pruned.fa.(label)=map_idxs(:)';
    if iscell(values)
        values=values(unq_idxs);
    else
        values=reshape(values(unq_idxs),1,[]);
    end
    ds_pruned.a.fdim.values{dim}=values;
end
