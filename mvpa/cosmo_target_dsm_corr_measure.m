function ds_sa = cosmo_target_dsm_corr_measure(dataset, args)
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
%
%   Returns
%    ds_sa           Struct with fields:
%      .samples      Scalar correlation value 
%      .sa           Struct with field:
%        .labels     {'rho'}  
%
%   
% ACC August 2013
    

    if nargin<2 error('Must supply args.'); end        
    if ~isfield(args,'target_dsm') error('Must supply args.target_dsm.'); end
    if ~isfield(args,'return_p') args.return_p = false; end
    
    % - compute the pair-wise distance between all dataset samples using
    %   pdist
    % - convert args.target_dsm using
    % - compute correlation between distances and converted target_dsm
% >@@>    
    pd = pdist(dataset.samples);

    sf=squareform(args.target_dsm);

    rho=corr(pd(:),sf(:));

% <@@<

    ds_sa=struct();
    ds_sa.samples=rho;
    ds_sa.sa.labels={'rho'};