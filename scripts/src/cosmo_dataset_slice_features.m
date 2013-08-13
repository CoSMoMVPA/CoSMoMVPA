function dataset=cosmo_dataset_slice_features(dataset, features_to_select)
% Slice a dataset by samples
%
% This function returns a dataset that is a copy of the original dataset
% but contains just the rows indictated in features_to_select, and the 
% corresponding values in feature attributes.

nfeatures_orig=size(dataset.samples,2);
dataset.samples=dataset.samples(:,features_to_select);

fns=fieldnames(dataset.fa);
n=numel(fns);
for k=1:n
    fn=fns{k};
    v=dataset.fa.(fn);
    if iscell(v)
        w={v{features_to_select}};
    else
        if numel(v)==nfeatures_orig
            v=v(:)'; % ensure row vector
        elseif size(v,2)~=nfeatures_orig
            error('illegal size for %s - expect Nx%d', fn, nfeatures_orig);
        end
        
        dataset.fa.(fn)=v(:,features_to_select);
    end
end

