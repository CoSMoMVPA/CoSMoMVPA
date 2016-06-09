function [ds, params]=cosmo_pca(ds, params)
% normalize dataset either by estimating or applying estimated parameters
%
% [ds, est_params]=cosmo_pca(ds, params)
%
% Inputs
%   ds            a dataset struct with field .samples of size PxQ, or a
%                 numeric array of that size
%   params        either the number of components to retain:
%                   - 0>params>1   (retain number of components that 
%                                   explain 'params' % of the variance)
%                   - 1<=params    (retain 'params' components)
%                 -or-
%                 previously estimated pca parameters using the 'params'
%                 output result from a previous call to this function.
%
% Output
%   ds            a dataset struct similar to ds, but with .samples data
%                 transformed using pca. Chan now refers to components
%   params        estimated parameters for pca. These can be re-used for a 
%                 second pca step of an independent dataset. For example, 
%                 parameters can be estimated from a training dataset and 
%                 then applied to a testing dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

if isempty(params)
    return;
end

apply_params=isstruct(params);

is_ds=isstruct(ds) && isfield(ds,'samples');

if is_ds
    samples=ds.samples;
else
    samples=ds;
end

if apply_params
    coeff=params.coeff;
    mu=params.mu;
    retain=params.retain;
else
    [coeff,~,~,~,explained,mu]=pca(samples);
    if params<1
        retain=cumsum(explained)<=params*100;
    else
        retain=(1:length(explained))<=params;
    end
    params=struct();
    params.mu=mu;
    params.coeff=coeff;
    params.retain=retain;
end
%de-mean and multiply with coefficients
samples=bsxfun(@minus,samples,mu)*coeff;

%apply retain mask
if is_ds
    ds.samples=samples;
    ds=cosmo_slice(ds,retain,2);
else
    ds=samples(:,retain);
end
