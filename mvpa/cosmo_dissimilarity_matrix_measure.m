function ds_dsm = cosmo_dissimilarity_matrix_measure(ds, varargin)
% Compute a dissimilarity matrix measure
%
% ds_dsm = cosmo_dissimilarity_matrix_measure(ds, varargin)
%
% Inputs:
%  - dataset:        dataset struct with fields .samples (PxQ) and 
%                    .sa.targets (Px1) for P samples and Q features.
%                    .sa.targets should be a permutation of 1:P.
%  - args:           an optional struct: 
%      args.metric:  a string with the name of the distance
%                    metric to be used by pdist (default: 'correlation')
%
%   Returns 
% Output
%    ds_sa           Struct with fields:
%      .samples      Nx1 flattened upper triangle of a dissimilarity matrix
%                    as returned by pdist, where N=P*(P-1)/2 is the 
%                    number of pairwise distances between all samples 
%                    in the dataset.
%      .sa           Struct with field:
%        .dsm_pairs  A Nx2 array indicating the pairs of indices in the
%                    square form of the dissimilarity matrix. That is,
%                    if .dsm_pairs(k,:)==[i,j] then .samples(k) contains
%                    the dissimlarity between the i-th and j-th sample
%                    target.
%
%   NB. pdist defaults to 'euclidean' distance, but correlation distance is
%       preferable for neural dissimilarity matrices
%
%   
% ACC August 2013
% NNO updated Sep 2013 to return a struct
    
    % check input
    if ~isfield(ds,'sa') || ~isfield(ds.sa,'targets')
        error('Missing field .sa.targets');
    end
    
    args=cosmo_structjoin('metric','correlation',varargin);

    % ensure that targets occur exactly once.
    targets=ds.sa.targets;
    ntargets=numel(targets);
    
    % unique targets
    classes=unique(targets);
    nclasses=numel(classes);
    
    % each should occur exactly once
    if nclasses~=ntargets || ~isequal(classes,sort(targets))
        error(['.sa.targets should be permutation of unique targets; '...
                'to average samples with the same targets, consider '...
                'ds_mean=cosmo_fx(ds,@(x)mean(x,1),''targets'')'],...
                    nclasses);
    end
    
    % make new dataset
    ds_dsm=struct();
    
    % compute pair-wise distances between all samples using pdist,
    % then store them as samples in ds_dsm
    % >@@>
    dsm = pdist(ds.samples, args.metric)';
    
    % store dsm
    ds_dsm.samples=dsm;
    % <@@<
    
    % store single sample attribute: the pairs of sample attribute indices
    % used to compute the dsm.
    [i,j]=find(triu(repmat(1:nclasses,nclasses,1),1));
    
    ds_dsm.sa.dsm_pairs=[targets(i), targets(j)];