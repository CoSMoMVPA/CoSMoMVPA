function ds=cosmo_generate_synthetic_dataset(class_distance, nclasses, nsamples_per_class, nfeatures, nchunks, different_on_all_dimensions)
% generates a synthetic dataset
%
% ds=cosmo_generate_synthetic_dataset(class_distance, nclasses, nsamples_per_class, nfeatures, nchunks, different_on_all_dimensions)
%
% inputs:
%   class_distance       how far samples of different classes are away from
%                        each other. the k-th class differs on the k-th
%                        feature on average class_distance from the other
%                        classes (if different_on_all_dimensions), or
%                        differs from the other classes at the k-th, 
%                        (k+nclasses)-th, k+(2*nclasses)-th, etc dimension
%                        Standard gaussian noise is added to the
%                        samples. (default: 3)
%   nsamples_per_class   number of samples in each class (default: 20)
%   nfeatures            number of features (default: 50)
%   nclasses             number of classes (default: 4)
%   nchunks              number of features - should be a multiple of 
%                        nsamples_per_class (default: 5)
%
% output:
%   ds                   dataset structure with fields:
%                           ds.samples (NS x nfeatures) 
%                           ds.targets (NS x 1) in the range [1..nclasses]
%                           ds.chunks: (NS x 1) in the range [1..nchunks]
%                        where NS = nsamples_per_class * nclasses
%   
% NNO Aug 2013

if nargin<6 || isempty(different_on_all_dimensions), different_on_all_dimensions=false; end
if nargin<5 || isempty(nchunks), nchunks=5; end
if nargin<4 || isempty(nclasses), nclasses=4; end
if nargin<3 || isempty(nfeatures), nfeatures=50; end
if nargin<2 || isempty(nsamples_per_class), nsamples_per_class=20; end
if nargin<1 || isempty(class_distance), class_distance=3; end
    
if mod(nsamples_per_class, nchunks)~=0, 
    error('Cannot divide %d samples per class in %d chunks', numel(nsamples_per_class), nchunks);
end


s=rng;
rng('default');

nsamples=nsamples_per_class*nclasses;

data=zeros(nsamples,nfeatures);
targets=zeros(nsamples,1);
chunks=zeros(nsamples,1);
for k=1:nclasses
    pat=randn(nsamples_per_class,nfeatures); % random gaussian patterns
    if different_on_all_dimensions
        error('not implemented');
        % >>
        % <<
    else
        pat(:,k)=pat(:,k)+class_distance;  % add pat_dist in the k-th dimension
    end
    
    idxs=(k-1)*nsamples_per_class+(1:nsamples_per_class);
    data(idxs,:)=pat;
    targets(idxs)=k;
    chunks(idxs)=mod(0:(nsamples_per_class-1),nchunks)+1;
end
rng(s);

ds=struct();
ds.samples=data;
ds.sa.chunks=chunks;
ds.sa.targets=targets;