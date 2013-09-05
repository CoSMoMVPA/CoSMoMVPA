function vols=cosmo_map2array(dataset)
% Unflattens a dataset 
%
% vols=cosmo_unflatten_fmri_dataset(dataset)
%
% Input
%   dataset     dataset structure with fields a.voldim and
%               .fa.voxel_indices (e.g. from cosmo_fmri_dataset)
% 
% Ouput
%   vols        4D array with sample data, with the last dimension
%               representing the samples
%
% NNO Sep 2013
    
    
    dime3=dataset.a.voldim;
    samples=dataset.samples;
    nsamples=size(samples,1);
    
    if ~isfield(dataset.fa,'voxel_indices')
        error('missing voxel indices');
    end
    
    % convert voxel indices to linear indices
    ijk=dataset.fa.voxel_indices;
    lin=sub2ind(dime3, ijk(1,:), ijk(2,:), ijk(3,:));
    
    vol=zeros(dime3); % space for a single volume
    
    dime4=[dime3 nsamples];
    vols=zeros(dime4); % space for all volumes
    
    % store the data in the volumes (one by one)
    for k=1:nsamples
        vol(:)=0;
        vol(lin)=samples(k,:);
        vols(:,:,:,k)=vol;
    end
    