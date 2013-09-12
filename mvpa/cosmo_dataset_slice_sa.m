function dataset=cosmo_dataset_slice_sa(dataset, samples_to_select)
% Slice a dataset by samples, aka rows
%   
%   dataset = cosmo_dataset_slice_sa(dataset, samples_to_select)
%   
%   Input
%       dataset: an instance of cosmo_fmri_dataset with N samples
%       samples_to_select:  Either an Nx1 boolean mask, or a vector with 
%                           indices.
%   Returns
%       dataset:    an instance of an fmri_dataset that is a copy of the input dataset
%                   but contains just the rows indictated in sample_indices, and the 
%                   corresponding values in sample attributes.
%   Note
%    - this function is intended as an exercise. For a more powerful 
%      implementation that deals with cell inputs correctly,
%      consider using comso_dataset_slice(dataset, features_to_select).
%      
% See also: cosmo_dataset_slice
    
    %%
    % First slice the samples array by rows
    
    % >>
    dataset.samples=dataset.samples(samples_to_select,:);
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
        dataset.sa.(fn)=sa(samples_to_select,:);
    end
    % <<
    