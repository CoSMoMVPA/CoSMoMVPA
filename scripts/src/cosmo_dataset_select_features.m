function dataset=cosmo_dataset_select_features(dataset, features_to_select)

dataset.samples=dataset.samples(:, features_to_select);

fns=fieldnames(dataset.fa);
n=numel(fns);
for k=1:n
    fn=fns{k};
    v=dataset.fa.(fn);
    dataset.fa.(fn)=v(features_to_select);
end


