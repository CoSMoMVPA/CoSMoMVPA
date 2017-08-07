function [pca_samples,params]=cosmo_pca(samples,retain)
% Principal Component Analysis
%
% [pca_samples,params]=cosmo_pca(samples[,retain])
%
% Input:
%   samples                 M x N  numeric matrix
%   retain                  (optional) number of components to retain;
%                           must be less than or equal to N. Default: N
%
% Output:
%   pca_samples             M x retain samples in Principal Component
%                           space, after samples have been centered
%   params                  struct with fields:
%     .coef                 M x retain Principal Component coefficients
%     .mu                   M x 1 column-wise average of samples
%                           It holds that:
%                             samples=bsxfun(@plus,params.mu,...
%                                                 pca_samples*params.coef')
%     .explained            1 x N Percentage of explained variance
%
%
% Examples:
%     samples=[      2.0317   -0.8918   -0.8258;...
%                    0.5838    1.8439    1.1656;...
%                   -1.4437   -0.2617   -1.9207;...
%                   -0.5177    2.3387    0.4412;...
%                    1.1908   -0.2040   -0.2088;...
%                   -1.3265    2.7235    0.1476];
%     %
%     % apply PCA, keeping two dimensions
%     [pca_samples,params]=cosmo_pca(samples,2);
%     %
%     % show samples in PC space
%     cosmo_disp(pca_samples);
%     %|| [  -2.64     0.654
%     %||    0.923      1.43
%     %||   -0.723     -2.48
%     %||     1.64     0.265
%     %||    -1.46     0.569
%     %||     2.27    -0.438 ]
%     %
%     % show parameters
%     cosmo_disp(params);
%     %|| .coef
%     %||   [ -0.512     0.744
%     %||      0.794     0.219
%     %||      0.328     0.632 ]
%     %|| .mu
%     %||   [ 0.0864     0.925      -0.2 ]
%     %|| .explained
%     %||   [    66
%     %||      33.3
%     %||     0.676 ]
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2
        retain=[];
    end

    verify_parameters(samples,retain)
    ndim=get_number_of_components(samples,retain);

    % subtract mean
    mu=mean(samples,1);
    samples_demu=bsxfun(@minus, samples, mu);

    % singular value decomposition
    [u,s,w]=svd(samples_demu,'econ');

    % extract eigen values
    [nrow,ncol]=size(samples);
    samples_is_vector=nrow==1 || ncol==1;
    if samples_is_vector
        % single eigen value
        eigvals=s(1);
    else
        % take diagonal
        eigvals=diag(s);
    end

    if ndim==0
        % seperate case for zero dimensions
        pca_samples=zeros(1,0);
        coef=zeros(ncol,0);
    else
        pca_samples_rand_sign=bsxfun(@times,u(:,1:ndim),eigvals(1:ndim)');
        [coef,sgn]=max_abs_positive_columnwise(w(:,1:ndim));
        pca_samples=bsxfun(@times,pca_samples_rand_sign,sgn);
    end

    % store coefficients
    params=struct();
    params.coef=coef;
    params.mu=mu;


    nexpl=min([nrow-1,ncol]);
    if nrow==1 || ncol==0
        % special case for empty vecto with explained variance
        params.explained=zeros(1,0);
    else
        explained_ratio=eigvals'.^2;
        params.explained=100*explained_ratio(1:nexpl)/sum(explained_ratio);
    end


function ncomp=get_number_of_components(samples,retain)
    max_retain=size(samples,2);

    if isempty(retain)
        retain=max_retain;
    end

    if retain>max_retain
        error('retain argument %d must be less than %d',...
                                retain,max_retain);
    end

    [nrow,ncol]=size(samples);
    ncomp=min([nrow-1,ncol,retain]);



function [coef_pos,sgn]=max_abs_positive_columnwise(coef)
    % swap sign for each column in which the maximum absolute value is
    % negative. sgn contains the sign used in each column (-1 or 1)
    [unused,i]=max(abs(coef),[],1);
    [nrows,ncols]=size(coef);
    mx_idx=(0:(ncols-1))*nrows+i;
    mx=coef(mx_idx);

    sgn=(mx>0)*2-1;
    coef_pos=bsxfun(@times,coef,sgn);

function verify_parameters(samples,retain)
    if ~isnumeric(samples)
        error('samples argument must be numeric');
    end

    if numel(size(samples))>2
        error('samples argument must be a matrix');
    end

    if ~(isempty(retain) || ...
                    (isscalar(retain) && ...
                     retain>0 && ...
                     isequal(round(retain),retain)))
        error('retain argument must be positive integer');
    end
