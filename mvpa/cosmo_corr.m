function c=cosmo_corr(x,y,corr_type)
% Computes correlation - faster than than matlab's "corr" for Pearson.
%
% c=comso_corr(x[,y[,corr_type]])
%
% Inputs:
%   x          PxM matrix.
%   y          PxN matrix (optional). If omitted then y=x.
%   corr_type  'Pearson' or 'Spearman' or 'Kendall' (optional). If omitted 
%              then corrtype='Pearson' and the computation time is
%              significantly reduced for small matrices x and y (with 
%              /tiny/ numerical imprecisions).
% Output:
%   c          MxN matrix with c(i,j)=corr(x(:,i),y(:,j),'type',corr_type).
%
% Notes:
%  - this function does not compute probability values.
%
% Example:
% - % generate some random data. 
%   clear all
%   x=randn(100); y=randn(100);
%   % call the function first to avoid lookup delays; then measure time
%   corr(x,y); corr(x,y); tic; c=corr(x,y); toc
%   cosmo_corr(x,y); cosmo_corr(x,y); tic; cc=cosmo_corr(x,y); toc
%   % compute differences in output
%   delta=c-cc;
%   max_delta=max(abs(delta(:)));
%   n_eps=eps/max_delta; % how many epsilons
%   fprintf('max difference: %d (%d epsilons)\n',max_delta,n_eps)
%   % output:
%   > Elapsed time is 0.014310 seconds.
%   > Elapsed time is 0.001418 seconds.
%   > max difference: 1.110223e-16
%
% See also: corr
%
% NNO Sep 2013 (from NNO's phoebe_corr, July 2010)

if nargin<2 || isempty(y)
    y=x;
end

if nargin<3 || isempty(corr_type)
    corr_type='Pearson';
end

switch corr_type
    case 'Pearson'
        % subtract mean
        xd=bsxfun(@minus,x,mean(x));
        yd=bsxfun(@minus,y,mean(y));

        % normalization
        n=1/(size(x,1)-1);

        % standard deviation
        xs=(n*sum(xd .^ 2)).^-0.5;
        ys=(n*sum(yd .^ 2)).^-0.5;

        % compute correlations
        c=n * (xd' * yd) .* (xs' * ys);
    otherwise
        'fallback'
        % fall-back: use Matlab's function
        c=corr(x,y,'type',corr_type);
end