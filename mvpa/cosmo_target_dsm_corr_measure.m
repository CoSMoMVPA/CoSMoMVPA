function rho = cosmo_target_dsm_corr_measure(dataset, args)
%   rho = cosmo_target_dsm_corr_measure  
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
%
%   Returns rho: Correlation value 
%
%   
% ACC August 2013

% >>
    if nargin<2 error('Must supply args.'); end        
    if ~isfield(args,'target_dsm') error('Must supply args.target_dsm.'); end
    if ~isfield(args,'return_p') args.return_p = false; end
    pd = pdist(dataset.samples);
    
    sf=squareform(args.target_dsm);
    
    rho=corr(pd(:),sf(:));
    
% <<

end
