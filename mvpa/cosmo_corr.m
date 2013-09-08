function c=cosmo_corr(x,y)
% Computes pearson correlation - a lot quicker than matlab's "corr"
% function
%
% Syntax: C=PHOEBE_CORR(X,Y)
%
% Inputs:
%   X: PxM matrix
%   Y: PxN matrix
% Output:
%   C: MxN matrix with C(i,j)=corr(X(:,i),Y(:,j))
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

c=n * (xd' * yd) .* (xs' * ys);