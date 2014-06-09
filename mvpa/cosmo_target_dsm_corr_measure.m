function ds_sa = cosmo_target_dsm_corr_measure(ds, varargin)
% measure correlation with target dissimilarity matrix
%
% ds_sa = cosmo_target_dsm_corr_measure(dataset, args)
%
% Inputs:
%   ds             dataset struct with field .samples PxQ for P samples and
%                  Q features 
%   args           struct with fields:
%     .target_dsm  Either: 
%                  - target dissimilarity matrix of size PxP. It should have
%                    zeros on the diagonal and be symmetric.
%                  - target dissimilarity vector of size Nx1, with 
%                    N=P*(P-1)/2 the number of pairs of samples in ds.
%     .metric      Distance metric used in pdist to compute pair-wise
%                  distances between samples in ds. It accepts any
%                  metric supported by pdist (default: 'correlation')
%     .type:       Type of correlation between target_dsm and ds,
%                  one of 'Pearson' (default), 'Spearman', or 'Kendall'
%                  
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
    
    nsamples_pd=size(pd,1);
    target_dsm=params.target_dsm;
    
    if nsamples_pd==size(target_dsm,1)
        % target_dsm is a vector
        
        % check size
        if numel(target_dsm)~=nsamples_pd
            error('target_dsm should be column vector or square')
        end
        
        target_dsm_vec=target_dsm;
    else
        % target_dsm is a square matrix
        
        % convert params.target_dsm to squareform and store in 
        % 'target_dsm_vec'
        % >@@> 
        target_dsm_vec=squareform(params.target_dsm);
        % <@@<
    
        % check size
        if numel(pd) ~= numel(target_dsm_vec),
            error(['Size mismatch between dataset (%d) '...
                    'and target dsm (%d)'], ...
                        numel(pd) ~= numel(target_dsm_vec));
        end
    end

    % >@@> 
    % compute correlations between 'pd' and 'sf', store in 'rho'
    rho=cosmo_corr(pd(:),target_dsm_vec(:), params.type);
    % <@@<

    % store results
    ds_sa=struct();
    ds_sa.samples=rho;
    ds_sa.sa.labels={'rho'};
    ds_sa.sa.metric=params.metric;
    ds_sa.sa.type=params.type;