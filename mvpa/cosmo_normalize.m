function [ds, params]=cosmo_normalize(ds, params, dim)
% normalize dataset either by estimating or applying estimated parameters
%
% [ds, est_params]=cosmo_normalize(ds, norm_type[, dim])
%
% Inputs
%   ds            a dataset struct with field .samples of size PxQ, or a
%                 numeric array of that size
%   params        either the type of normalization:
%                   - 'demean'     (mean of zero)
%                   - 'zscore'     (demean and unit variance)
%                   - 'scale_unit' (scale to interval [-1,1])
%                 -or-
%                 previously estimated parameters using the 'params'
%                 output result from a previous call to this function.
%   dim           1 or 2, indicating along with dimension of ds to
%                 normalize (if params it not a string and ends with '1' or
%                 2').
%
% Output
%   ds_norm       a dataset struct similar to ds, but with .samples data
%                 normalized. If the input was a numeric array then ds_norm
%                 is a numeric array as well.
%   params        estimated parameters for normalization. These can be
%                 re-used for a second normalization step of an independant
%                 dataset. For example, parameters can be estimated from a
%                 training dataset and then applied to a testing dataset
%
%
% Examples:
%     ds=struct();
%     ds.samples=reshape(1:15,5,3)*2;
%     cosmo_disp(ds);
%     > .samples
%     >   [  2        12        22
%     >      4        14        24
%     >      6        16        26
%     >      8        18        28
%     >     10        20        30 ]
%     %
%     % demean along first dimension
%     dsn=cosmo_normalize(ds,'demean',1);
%     cosmo_disp(dsn);
%     > .samples
%     >   [ -4        -4        -4
%     >     -2        -2        -2
%     >      0         0         0
%     >      2         2         2
%     >      4         4         4 ]
%     %
%     % demean along second dimension
%     dsn=cosmo_normalize(ds,'demean',2);
%     cosmo_disp(dsn);
%     > .samples
%     >   [ -10         0        10
%     >     -10         0        10
%     >     -10         0        10
%     >     -10         0        10
%     >     -10         0        10 ]
%     %
%     % scale to range [-1,1] along first dimension
%     dsn=cosmo_normalize(ds,'scale_unit',1);
%     cosmo_disp(dsn);
%     > .samples
%     >   [   -1        -1        -1
%     >     -0.5      -0.5      -0.5
%     >        0         0         0
%     >      0.5       0.5       0.5
%     >        1         1         1 ]
%     %
%     % z-score along first dimension
%     dsn=cosmo_normalize(ds,'zscore',1);
%     cosmo_disp(dsn);
%     > .samples
%     >   [  -1.26     -1.26     -1.26
%     >     -0.632    -0.632    -0.632
%     >          0         0         0
%     >      0.632     0.632     0.632
%     >       1.26      1.26      1.26 ]
%     %
%     % z-score along second dimension
%     dsn=cosmo_normalize(ds,'zscore',2);
%     cosmo_disp(dsn);
%     > .samples
%     >   [ -1         0         1
%     >     -1         0         1
%     >     -1         0         1
%     >     -1         0         1
%     >     -1         0         1 ]
%     %
%     % use samples 1, 3, and 4 to estimate parameters ('training set'),
%     % and apply these to samples 2 and 5
%     ds_train=cosmo_slice(ds,[1 3 4]);
%     ds_test=cosmo_slice(ds,[2 5]);
%     [dsn_train,params]=cosmo_normalize(ds_train,'scale_unit', 1);
%     cosmo_disp(dsn_train);
%     > .samples
%     >   [    -1        -1        -1
%     >     0.333     0.333     0.333
%     >         1         1         1 ]
%     %
%     % show estimated parameters (min and max for each column, in this
%     % case)
%     cosmo_disp(params);
%     > .method
%     >   'scale_unit'
%     > .dim
%     >   [ 1 ]
%     > .min
%     >   [ 2        12        22 ]
%     > .max
%     >   [ 8        18        28 ]
%     %
%     % apply parameters to test dataset
%     dsn_test=cosmo_normalize(ds_test,params);
%     cosmo_disp(dsn_test);
%     > .samples
%     >   [ -0.333    -0.333    -0.333
%     >       1.67      1.67      1.67 ]
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

if isempty(params) || (ischar(params) && strcmp(params,'none'))
    return;
end

if nargin<3, dim=[]; end

apply_params=isstruct(params);
if apply_params;
    if ~isempty(dim) && params.dim~=dim
        error('Dim specified as %d, but estimates used %d',dim,params.dim);
    end
elseif ischar(params)
    params=get_method_and_dim(params,dim);
else
    error('norm_spec must be struct or string');
end

method=params.method;
dim=params.dim;


is_ds=isstruct(ds) && isfield(ds,'samples');

if is_ds
    samples=ds.samples;
else
    samples=ds;
end

switch method
    case 'demean'
        if apply_params
            mu=params.mu;
        else
            mu=mean(samples,dim);
            params.mu=mu;
        end
        samples=bsxfun(@minus,samples,mu);

    case 'zscore'
        if apply_params
            mu=params.mu;
            sigma=params.sigma;
        else
            mu=mean(samples,dim);
            sigma=std(samples,[],dim);
            params.mu=mu;
            params.sigma=sigma;
        end
        d=bsxfun(@minus,samples,mu);

        if isempty(sigma)
            % Octave 3.8.2 on Ubuntu gives it the wrong size
            sigma=zeros(size(d));
        end

        % In Octave, std can give non-NaN even with NaN input
        nan_mask=any(isnan(samples),dim);
        sigma(nan_mask)=NaN;

        samples=bsxfun(@rdivide,d,sigma);

    case 'scale_unit'
        if apply_params
            min_=params.min;
            max_=params.max;
        else
            min_=min(samples,[],dim);
            max_=max(samples,[],dim);
            params.min=min_;
            params.max=max_;

        end
        samples=bsxfun(@times,1./(max_-min_),...
                            (bsxfun(@minus,samples,min_)))*2-1;

    otherwise
        error('Unsupported normalization: %s', method);

end

nan_msk=~isfinite(samples);
if any(nan_msk(:))
    cosmo_warning('%d samples are NaN or Inf after normalization', ...
                        sum(nan_msk(:)));
end

if is_ds
    ds.samples=samples;
else
    ds=samples;
end

function params=get_method_and_dim(params,dim_arg)
    assert(ischar(params));
    assert(numel(params)>0);

    dim=[];
    method=params;

    if isempty(dim_arg)
        if isempty(dim)
            dim=1;
        end
    else
        if isempty(dim)
            dim=dim_arg;
        else
            error(['Cannot have third argument when second argument '...
                        'ends with a number']);
        end
    end


    params=struct();
    params.method=method;
    params.dim=dim;
