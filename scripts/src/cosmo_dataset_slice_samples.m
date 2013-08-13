function dataset=cosmo_dataset_slice_samples(dataset, samples_to_select)
% Slice a dataset by samples
%
% This function returns a dataset that is a copy of the original dataset
% but contains just the rows indictated in sample_indices, and the 
% corresponding values in sample attributes.

nsamples_orig=size(dataset.samples,1);
dataset.samples=dataset.samples(samples_to_select,:);


fns=fieldnames(dataset.sa);
n=numel(fns);
for k=1:n
    fn=fns{k};
    v=dataset.sa.(fn);
    if iscell(v)
        w={v{samples_to_select}};
    else
        if numel(v)==nsamples_orig
            v=v(:); % ensure column vector
        elseif size(v,1)~=nsamples_orig
            error('illegal size for %s - expect Nx%d', fn, nsamples_orig);
        end
        dataset.sa.(fn)=v(samples_to_select,:);
    end
end

