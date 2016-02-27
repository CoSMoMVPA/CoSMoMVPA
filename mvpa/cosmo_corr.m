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
%              /tiny/ numerical imprecisions) by the use of a custom
%              implementation.
%              Using 'Spearman' or 'Kendall' required the matlab stats
%              toolbox.
% Output:
%   c          MxN matrix with c(i,j)=corr(x(:,i),y(:,j),'type',corr_type).
%
% Notes:
%  - this function does not compute probability values.
%  - Using 'Spearman' or 'Kendall' for corr_type requires the matlab stats
%    toolbox.
%
% Example:
%   % generate some pseudo-random data.
%   x=reshape(mod(2:7:100,41),5,[]);
%   y=reshape(mod(1:7:100,37),5,[]);
%   % compute builtin corr with cosmo_corr
%   % call the function first to avoid lookup delays; then measure time
%   c=corr(x,y);
%   cc=cosmo_corr(x,y);
%   % compute differences in output
%   delta=c-cc;
%   max_delta=max(abs(delta(:)));
%   fprintf('difference not greater than eps: %d\n',max_delta<=eps);
%   > difference not greater than eps: 1
%
% See also: corr
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    y_as_x=false;

    if nargin<2
        corr_type='Pearson';
        y_as_x=true;
    elseif ischar(y)
        corr_type=y;
        y_as_x=true;
    elseif nargin<3
        corr_type='Pearson';
    end

    if y_as_x
        y=x;
    end

    switch corr_type
        case 'Pearson'
            % speed-optimized version
            nx=size(x,1);
            ny=size(y,1);

            % subtract mean
            xd=bsxfun(@minus,x,sum(x,1)/nx);
            yd=bsxfun(@minus,y,sum(y,1)/ny);

            % normalization
            n=1/(size(x,1)-1);

            % standard deviation
            xs=(n*sum(xd .^ 2)).^-0.5;
            ys=(n*sum(yd .^ 2)).^-0.5;

            % compute correlations
            c=n * (xd' * yd) .* (xs' * ys);

            if y_as_x
                % ensure diagonal elements are 1
                c=(c+c')*.5;
                dc=diag(c);
                c=(c-diag(dc))+eye(numel(dc));
            end

        otherwise
            % fall-back: use Matlab's function
            % will puke if no Matlab stat toolbox
            c=corr(x,y,'type',corr_type);
    end
