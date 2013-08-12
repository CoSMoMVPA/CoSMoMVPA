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