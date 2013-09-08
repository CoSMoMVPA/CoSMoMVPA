function c=cosmo_corr(x,y)
% Computes pearson correlation - faster than than matlab's "corr".
%
% c=comso_corr(x[,y])
%
% Inputs:
%   x      PxM matrix
%   y      PxN matrix (optional). If omitted then y=x.
% Output:
%   c      MxN matrix with c(i,j)=corr(x(:,i),y(:,j))
%
% See also: corr
%
% NNO Sep 2013 (from phoebe_corr, July 2010)

if nargin<2
    y=x;
end

% subtract mean
xd=bsxfun(@minus,x,mean(x));
yd=bsxfun(@minus,y,mean(y));

% normalization
n=1/(size(x,1)-1);

% standard deviation
xs=bsxfun(@power,n*sum(xd .* xd),-0.5);
ys=bsxfun(@power,n*sum(yd .* yd),-0.5);

% compute correlations
c=n * (xd' * yd) .* (xs' * ys);