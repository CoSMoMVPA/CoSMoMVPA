function ds_stacked=cosmo_dataset_stack_samples(datasets)

if ~iscell(datasets)
    error('expected cell input');
end

n=numel(datasets);
if n==0
    error('empty cell input')
end

ds_stacked=datasets{1};

fns=fieldnames(ds_stacked.sa);
nfn=numel(fns);
for k=1:nfn
    fn=fns{k};
    vs=cell(n,1);
    for j=1:n
        ds=datasets{j};
        if ~isfield(ds.sa,fn)
            error('field name not found: %s', fn);
        end
        vs{j}=ds.sa.(fn);
    end
    ds_stacked.sa.(fn)=cat(1,vs{:});
end

fns=fieldnames(ds_stacked.fa);
nfn=numel(fns);

for k=1:nfn
    fn=fns{k};
    for j=1:n
        ds=datasets{j};
        if ~isfield(ds.fa,fn)
            error('field name not found: %s', fn);
        end
        if ~isequal(ds.fa.(fn), ds_stacked.fa.(fn))
            error('value mismatch: %s', fn);
        end 
    end
end
    
vs=cell(n,1);
for k=1:n
    vs{k}=datasets{k}.samples;
end
ds_stacked.samples=cat(1,vs{:});
