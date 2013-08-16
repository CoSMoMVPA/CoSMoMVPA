function ni=cosmo_map2nifti(dataset, fn)
% maps a dataset structure to a nifti structure or file
% 
% Usage 1: ni=cosmo_map2nifti(dataset) returns a nifti structure ni
% Usage 2: cosmo_map2nifti(dataset, fn) saves dataset as nifti file fn
%
% NNO Aug 2013

samples=dataset.samples;
[nsamples, nfeatures]=size(samples);

ni=dataset.a.imghdr;
ni.hdr.dime.dim(5)=nsamples;
dime=ni.hdr.dime.dim;
dime3=dime(2:4);
dime4=dime(2:5);

if ~isfield(dataset.fa,'voxel_indices')
    error('missing voxel indices');
end

% convert voxel indices to linear indices
ijk=dataset.fa.voxel_indices;
lin=sub2ind(dime3, ijk(1,:), ijk(2,:), ijk(3,:));

vol=zeros(dime3);
vols=zeros(dime4);
for k=1:nsamples
    vol(:)=0;
    vol(lin)=samples(k,:);
    vols(:,:,:,k)=vol;
end

ni.img=vols;

if nargin>1
    save_nii(ni, fn);
end






