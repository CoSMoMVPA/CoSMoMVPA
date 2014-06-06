function ds_sa = cosmo_target_dsm_corr_measure(ds, varargin)
%   ds_sa = cosmo_target_dsm_corr_measure(dataset, args)
%
%   A **dataset measure** that computes the correlation between a target
%   dissimilarity matrix and the dissimilarity matrix of the input dataset
%   samples 
%
%   Inputs
%       dataset:    an instance of a cosmo_fmri_dataset
%       args:       struct with mandatory field target_dsm and optional field
%                   type 
%           args.target_dsm:    Target dissimilarity matrix, flattened upper
%                               triangle, must be same size as dsm for dataset
%           args.type:  [Optional] Type of correlation can be any 'type' that matlab's
%                       corr function can take. Default: 'pearson'
%           args.metric Optional type of distance metric used in pdist.
%                       Default: 'correlation'
%
%   Returns
%    ds_sa           Struct with fields:
%      .samples      Scalar correlation value 
%      .sa           Struct with field:
%        .labels     {'rho'}  
%
%   
% ACC August 2013
    
    % process input arguments
    params=cosmo_structjoin('type','Pearson',... % set default
                            'metric','correlation',...
                            varargin);
    
    % - compute the pair-wise distance between all dataset samples using
    %   pdist and store in 'pd'
    % >@@>    
    pd = pdist(ds.samples, params.metric);
    % <@@<
    
    % convert params.target_dsm to squareform and store in 'sf'
    % >@@> 
    sf=squareform(params.target_dsm);
    % <@@<
    
    % check size
    if numel(pd) ~= numel(sf),
        error('Size mismatch between dataset and target dsm');
    end

    % >@@> 
    % compute correlations between 'pd' and 'sf', store in 'rho'
    rho=cosmo_corr(pd(:),sf(:), params.type);
    % <@@<

    ds_sa=struct();
    ds_sa.samples=rho;
    ds_sa.sa.labels={'rho'};