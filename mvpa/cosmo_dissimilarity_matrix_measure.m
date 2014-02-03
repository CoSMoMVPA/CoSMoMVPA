function ds_sa = cosmo_dissimilarity_matrix_measure(dataset, varargin)
% Compute a dissimilarity matrix measure
%
% ds_sa = cosmo_dsm_measure(dataset, varargin)
%
% Inputs:
%  - dataset:        an instance of a cosmo_fmri_dataset
%  - args:           an optional struct: 
%      args.metric:  a string with the name of the distance
%                    metric to be used by pdist (default: 'correlation')
%
%   Returns 
% Output
%    ds_sa           Struct with fields:
%      .samples      the flattened upper triangle of a dissimilarity matrix as
%                    returned by pdist, but conforming to the output for a dataset
%                    measure (i.e., N x 1 array, where N is the number of pairwise
%                    distances between all samples in the dataset).
%      .sa           Struct with field:
%        .dsm_pairs  A Px2 array indicating the pairs of indices in the
%                    square form of the dissimilarity matrix. That is,
%                    if .dsm_pairs(k,:)==[i,j] then .samples(k) contains
%                    the dissimlarity between the i-th and j-th sample.
%
%   NB. pdist defaults to 'euclidean' distance, but correlation distance is
%       preferable for neural dissimilarity matrices
%
%   
% ACC August 2013
% NNO updated Sep 2013 to return a struct
    
    args=cosmo_structjoin('metric',correlation,varargin);
% >@@>
    dsm = pdist(dataset.samples, args.metric)';
% <@@<

    % store in a struct
    ds_sa=struct();
    ds_sa.samples=dsm;
    
    % as sample attributes store the pairs of sample attribute indicues
    % used to compute the dsm.
    nclasses=size(dsm,1);
    [i,j]=find(triu(repmat(1:nclasses,nclasses,1)));
    ds_sa.sa.dsm_pairs=[i j];