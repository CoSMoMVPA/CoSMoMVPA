function [shrinkage,shr_cov]=cosmo_cov_shrinkage(uncentered_xs)
% compute Ledoit-Wolf shrinkage and covariance matrix
%
% [shrinkage,shr_cov]=cosmo_cov_shrinkage(xs)
%
% Input:
%   xs                      PxQ data matrix for P samples (observations)
%                           and Q features
%
% Outputs:
%   shrinkage               Ledoit-Wolf shrinkage value between 0 and 1
%   shr_cov                 QxQ shrinkage coverage matrix based on the
%                           coveriance in xs and the shrinkage value
%
% Reference:
%   - Ledoit, Olivier, and Michael Wolf. "A well-conditioned estimator for
%     large-dimensional covariance matrices." Journal of multivariate
%     analysis 88.2 (2004): 365-411.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if ~(isnumeric(uncentered_xs) ...
            && numel(size(uncentered_xs))==2)
        error('input must be numeric 2D matrix');
    end

    [nsamples,nfeatures]=size(uncentered_xs);
    xs=bsxfun(@minus,mean(uncentered_xs,1),uncentered_xs);

    % sample covariance matrix
    s=(xs'*xs)/nsamples;
    if nfeatures<=1
        shrinkage=0;
        shr_cov=s;
    else
        % Note: Lemma's refer to the Ledoit & Wolf paper

        % Lemma 3.2 (modified)
        m=trace(s)/nfeatures;

        % Lemma 3.3
        d2=fro2_norm(s-m*eye(nfeatures))^2;

        % Lemma 3.4
        b2=0;
        for k=1:nsamples
            b2=b2+fro2_norm(xs(k,:)'*xs(k,:)-s)^2/(nsamples^2);
        end

        % restrict to range [0,1]
        shrinkage=b2/d2;
        if shrinkage<0
            shrinkage=0;
        elseif shrinkage>1
            shrinkage=1;
        end

        if nargout>=2
            % compute shrinkage matrix
            shr_cov=shrinkage*m*eye(nfeatures) ...
                    + (1-shrinkage)*s;
        end
    end

function y=fro2_norm(x)
    y=norm(x,'fro');