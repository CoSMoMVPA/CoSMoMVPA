function dataset=cosmo_dataset_slice_fa(dataset, features_to_select)
% Slice a dataset by samples, aka rows
%   
%   dataset = cosmo_dataset_slice_sa(dataset, features_to_select)
%   
%   Input
%       dataset: an instance of cosmo_fmri_dataset with N samples
%       features_to_select:  Either an Nx1 boolean mask, or a vector with 
%                           indices.
%   Returns
%       dataset:    an instance of an fmri_dataset that is a copy of the input dataset
%                   but contains just the rows indictated in features_to_select, and the 
%                   corresponding values in feature attributes.

%%
% First slice the samples array by rows

% >>
dataset.samples=dataset.samples(:,features_to_select);
% <<

%%
%   Then go through each of the sample attributes and slice each one.
%
%   Hint: we used the matlab function 'fieldnames' to list the field in
%   dataset.sa in case it is missing either targets or chunk, or in case there
%   may be extra unknown sample attributes

% >>
fns = fieldnames(dataset.sa); 
n = numel(fns);

for k=1:n
    fn = fns{k};
    sa = dataset.sa.(fn);
    dataset.sa.(fn)=sa(:,features_to_select);
end
% <<
