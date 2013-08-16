function dsm = cosmo_dissimilarity_matrix(dataset, args)
%   A wrapper function for Matlab's pdist function that conform to the
%   definition of a **dataset measure**
%
%   Inputs
%       dataset:    an instance of a cosmo_fmri_dataset
%       args:       an optional struct: 
%           args.metric: a **cell array** containing the name of the distance
%                       metric to be used by pdist (default: 'correlation')
%
%   Returns 
%       dsm:    the flattened upper triangle of a dissimilarity matrix as
%               returned by pdist, but conforming to the output for a dataset
%               measure (i.e., N x 1 array, where N is the number of pairwise
%               distances between all samples in the dataset).
%
%   NB. pdist defaults to 'euclidean' distance, but correlation distance is
%       preferable for neural dissimilarity matrices
%
%       Also, args.metric is a cell array, because, for some reason matlab
%       doesn't like struct fields to be strings
%   
%   
% ACC August 2013

    if nargin<2 args.metric={'correlation'}; end
    if ~isfield(args,'metric') args.metric = {'correlation'}; end
    dsm = pdist(dataset.samples, args.metric{1})';


end
