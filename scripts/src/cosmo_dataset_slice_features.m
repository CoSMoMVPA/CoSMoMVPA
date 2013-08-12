function dataset=cosmo_dataset_slice_features(dataset, features_to_select)
% Slice a dataset by samples
%
% This function returns a dataset that is a copy of the original dataset
% but contains just the rows indictated in features_to_select, and the 
% corresponding values in feature attributes.

dataset.samples=dataset.samples(:,features_to_select);

fns=fieldnames(dataset.fa);
n=numel(fns);
for k=1:n
    fn=fns{k};
    v=dataset.fa.(fn);
    if iscell(v)
        w={v{features_to_select}};
    else
        dataset.sa.(fn)=v(:,features_to_select);
    end
end

