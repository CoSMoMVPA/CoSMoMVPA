function dataset=cosmo_dataset_select_samples(dataset, samples_to_select)

dataset.samples=dataset.samples(samples_to_select,:);

fns=fieldnames(dataset.fa);
n=numel(fns);
for k=1:n
    fn=fns{k};
    v=dataset.fa.(fn);
    dataset.fa.(fn)=v(samples_to_select);
end

