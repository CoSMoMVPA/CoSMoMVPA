function y=cosmo_norminv(p,mu,sd)
% compute inverse normal cumulative distribution function
%
% y=cosmo_norminv(p[,mu[,sd]])
%
% Inputs:
%   p               array with p values
%   mu              optional scalar or array with mean values, default 0
%   sd              optional scalar or array with standard deviation
%                   values, default 1
%
% Output:
%   y               array with the same size as p, so that if
%                       z=(y-mu)/sd
%                   it holds that normcdf(z)==p
%
% Notes:
%   - mu and sd can be scalar or arrays, but their size must be compatible
%     with that of p.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<3
        sd=1;
    end

    if nargin<2
        mu=0;
    end

    z=sqrt(2)*erfinv(2*p-1);
    y=bsxfun(@plus,mu,bsxfun(@times,z,sd));


