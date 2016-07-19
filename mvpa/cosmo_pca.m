function [ds, pca_params]=cosmo_pca(ds, varargin)
% normalize dataset either by estimating or applying estimated parameters
%
% [ds, pca_params]=cosmo_pca(ds[, pca_params, pca_explained_count, 
%                            pca_explained_ratio])
%
% Inputs
%   ds            a dataset struct with field .samples of size PxQ, or a
%                 numeric array of that size
%   pca_params    previously estimated pca parameters using the 
%                 'pca_params' output result from a previous call to this 
%                 function
%   pca_explained_count    retain only the first 'pca_explained_count' 
%                          components
%   pca_explained_ratio    retain the first components that explain 
%                 'pca_explained_ratio' percent of the variance (value
%                 between 0 and 1, where 1 retains all components)
%
% Output
%   ds            a dataset struct similar to ds, but with .samples data
%                 transformed using pca.
%   params        estimated parameters for pca. These can be re-used for a 
%                 second pca step of an independent dataset. For example, 
%                 parameters can be estimated from a training dataset and 
%                 then applied to a testing dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

opt=cosmo_structjoin(varargin);

apply_params = isfield(opt,'pca_params');
pca_explained_count = isfield(opt,'pca_explained_count');
pca_explained_ratio = isfield(opt,'pca_explained_ratio');
    
%they are mutually exclusive
if sum([apply_params,pca_explained_count,pca_explained_ratio])>1
    error(['apply_params, pca_explained_count, pca_explained_ratio '...
      'are mutually exclusive.']);
end

is_ds=isstruct(ds) && isfield(ds,'samples');

if is_ds
    samples=ds.samples;
else
    samples=ds;
end

if apply_params
    pca_params=opt.pca_params;
    coeff=pca_params.coeff;
    mu=pca_params.mu;
    if size(coeff,1)~=size(samples,2)
        error(['Expecting ',num2str(size(coeff,1)),' features for the ',...
            'PCA transformation, but ',num2str(size(samples,2)),...
            ' features were provided.'])
    end
    retain=pca_params.retain;
    %de-mean and multiply with previously computed coefficients
    samples=bsxfun(@minus,samples,mu)*coeff;
else
    [coeff,samples,unused1,unused2,explained,mu]=pca(samples); %#ok<ASGLU>
    pca_params=struct();
    pca_params.mu=mu;
    pca_params.coeff=coeff;
    if pca_explained_count
        pca_explained_count=opt.pca_explained_count;
        %check for valid values
        if pca_explained_count==0
            error('pca_explained_count should be greater than 0');
        elseif pca_explained_count>length(explained)
            error(['pca_explained_count should be smaller than the '...
                'number of features']);
        end
        %retain the first n components, sorted by their explained variance
        pca_params.pca_explained_count=pca_explained_count;
        retain=(1:length(explained))<=pca_explained_count;
    elseif pca_explained_ratio
        pca_explained_ratio=opt.pca_explained_ratio;
        %check for valid values
        if pca_explained_ratio<=0
            error('pca_explained_ratio should be greater than 0');
        elseif pca_explained_ratio>1
            error('pca_explained_ratio should be smaller than 1');
        end
        %retain the first components that explain the amount of variance 
        pca_params.pca_explained_ratio=pca_explained_ratio;
        retain=cumsum(explained)<=pca_explained_ratio*100;
    else
        %retain everything
        retain = true(1,length(explained));
    end
    pca_params.retain=retain;
end

%apply retain mask
if is_ds
    ds.samples=samples;
    ds.fa = struct();
    ds.fa.comp=1:size(samples,2);
    ds.a.fdim.labels={'comp'};
    ds.a.fdim.values={1:size(samples,2)};
    ds=cosmo_slice(ds,retain,2);
else
    ds=samples(:,retain);
end
