function [pca_ds, pca_params]=cosmo_map_pca(ds, varargin)
% normalize dataset either by estimating or applying estimated parameters
%
% [pca_ds, pca_params]=cosmo_map_pca(ds[, ...])
%
% Inputs
%   ds                          a dataset struct with field .samples of
%                               numeric array of size PxQ, or a
%                               numeric array of that size
%   'pca_params',p              previously estimated pca parameters using
%                               the 'pca_params' output result from a
%                               previous call to this function
%   'pca_explained_count',c     retain only the first components
%   'pca_explained_ratio',r     retain the first components that explain
%                               (r * 100)% of the
%                               variance (value between 0 and 1, where 1
%                               retains all components)
%   'max_feature_count',mx      Raise an error if Q>mx (default: mx=1000).
%                               This protects against possible comutations
%                               that require much memory and/or time when
%                               computing singular value decompositions
%
% Output
%   pca_ds                      a dataset struct similar to ds, but
%                               with .samples data transformed using pca.
%                               If the input was a numeric array, then
%                               pca_ds is numeric as well
%   params                      estimated parameters for pca. These can be
%                               re-used for a second pca step of an
%                               independent dataset. For example,
%                               parameters can be estimated from a
%                               training dataset and then applied to a
%                               testing dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults=struct();
    defaults.max_feature_count=1000;

    opt=cosmo_structjoin(defaults,varargin);

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

    if size(samples,2)>opt.max_feature_count
        error(['A large number of features (%d) was found, '...
                    'exceeding the safety limit max_feature_count=%d '...
                    'for the %s function.\n'...
                    'This limit is imposed because computing the '...
                    'singular value decomposition may require lots '...
                    'of time and/or memory'...
                    'The safety limit can be changed by setting '...
                    'the ''max_feature_count'' option to another '...
                    'value, but large values ***may freeze or crash '...
                    'the machine***.'],...
                    size(samples,2),opt.max_feature_count);
    end

    % estimate or apply parameters
    if apply_params
        [full_samples,pca_params]=pca_apply(samples,opt);
    else
        [full_samples,pca_params]=pca_estimate(samples,opt);
        full_samples=full_samples(:,pca_params.retain);

    end

    % set output
    if is_ds
        pca_ds=struct();
        pca_ds.samples=full_samples;
        pca_ds.fa = struct();
        pca_ds.fa.comp=1:size(full_samples,2);
        pca_ds.a.fdim.labels={'comp'};
        pca_ds.a.fdim.values={1:size(samples,2)};
    else
        pca_ds=full_samples;
    end



function [full_samples,pca_params]=pca_apply(samples,opt)
    verify_samples(samples);
    apply_verify_opt(opt);

    pca_params=opt.pca_params;
    coef=pca_params.coef;
    mu=pca_params.mu;
    if size(coef,1)~=size(samples,2)
        error(['Expecting ',num2str(size(coef,1)),' features for the ',...
            'PCA transformation, but ',num2str(size(samples,2)),...
            ' features were provided.'])
    end

    %de-mean and multiply with previously computed coefficients

    full_samples=bsxfun(@minus,samples,mu)*coef;


function verify_samples(samples)
    if ~isnumeric(samples)
        error('samples must be numeric');
    end
    if numel(size(samples))~=2
        error('samples must be a matrix');
    end

function apply_verify_opt(opt)
    assert(isstruct(opt));
    assert(isfield(opt,'pca_params'));
    pca_params=opt.pca_params;

    raise_error=true;
    cosmo_isfield(pca_params,{'coef','mu','retain'},raise_error);



function [full_samples,pca_params]=pca_estimate(samples,opt)
    verify_samples(samples);

    [full_samples,pca_params]=cosmo_pca(samples);
    explained=pca_params.explained;

    has_pca_explained_count = isfield(opt,'pca_explained_count');
    has_pca_explained_ratio = isfield(opt,'pca_explained_ratio');

    ndim=size(full_samples,2);

    if has_pca_explained_count
        pca_explained_count=opt.pca_explained_count;
        %check for valid values
        if pca_explained_count<=0
            error('pca_explained_count should be greater than 0');
        elseif round(pca_explained_count)~=pca_explained_count
            error('pca_explained_count must be an integer');
        elseif pca_explained_count>length(pca_params.explained)
            error(['pca_explained_count should be smaller than '...
                    'or equal to than the '...
                    'number of features']);
        end

        %retain the first ndim components
        nretain=pca_explained_count;

    elseif has_pca_explained_ratio
        pca_explained_ratio=opt.pca_explained_ratio;
        %check for valid values
        if pca_explained_ratio<=0
            error('pca_explained_ratio should be greater than 0');
        elseif pca_explained_ratio>1
            error('pca_explained_ratio should not be greater than 1');
        end
        %retain the first components that explain the amount of variance
        cum_explained=cumsum(explained);
        nretain=find(cum_explained>pca_explained_ratio*100,1,'first');

        if isempty(nretain)
            % deal wtih rounding error
            assert(100-cum_explained(end)<1e-4);
            nretain=ndim;
        end

    else
        %retain everything
        nretain = ndim;
    end

    retain=[true(1,nretain), false(1,ndim-nretain)];

    pca_params.retain=retain;
    pca_params.coef=pca_params.coef(:,retain);
    pca_params=rmfield(pca_params,'explained');

