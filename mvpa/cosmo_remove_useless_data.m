function ds_useful=cosmo_remove_useless_data(ds, dim, type)
% remove 'useless' (constant and/or non-finite) samples or features
%
% ds_useful=cosmo_remove_useless_data(ds[, dim][, type)]
%
% Inputs:
%   ds              dataset struct
%   dim             optional dimension along which useless data is found:
%                   dim=1: along samples  (keeping useful features)
%                   dim=2: along features (keeping useful samples)
%                   default: 1
%   type            optional type of usefulness, one of:
%                   'variable'  : keep non-constant data
%                   'finite'    : keep non-finite (NaN or Inf) data
%                   'all'       : keep variable and finite data
%                   default: all
% Output:
%   ds_useful       dataset struct sliced so that useless data along the
%                   dim-th dimension is removed.
%
% Examples:
%     ds=cosmo_synthetic_dataset('nchunks',2);
%     %
%     % make some data elements useless
%     ds.samples(1,1)=NaN;    % non-finite
%     ds.samples(2,3)=Inf;    % non-finite
%     ds.samples(3,:)=7;      % constant along sample dimension (dim=1)
%     ds.samples(:,4)=7;      % constant along feature dimension (dim=2)
%     %
%     cosmo_disp(ds.samples);
%     > [   NaN     0.319      3.58         7    -0.124     0.671
%     >    1.83     0.367       Inf         7      3.16     -1.21
%     >       7         7         7         7         7         7
%     >   0.862      2.02      3.03         7      3.09      1.63 ]
%     %
%     % remove all features that are useless
%     ds_useful=cosmo_remove_useless_data(ds);
%     cosmo_disp(ds_useful.samples);
%     > [ 0.319    -0.124     0.671
%     >   0.367      3.16     -1.21
%     >       7         7         7
%     >    2.02      3.09      1.63 ]
%     %
%     % remove all features that are constant
%     ds_variable=cosmo_remove_useless_data(ds,1,'variable');
%     cosmo_disp(ds_variable.samples);
%     > [ 0.319      3.58    -0.124     0.671
%     >   0.367       Inf      3.16     -1.21
%     >       7         7         7         7
%     >    2.02      3.03      3.09      1.63 ]
%     %
%     % remove all features that are not finite
%     ds_finite=cosmo_remove_useless_data(ds,1,'finite');
%     cosmo_disp(ds_finite.samples);
%     > [ 0.319         7    -0.124     0.671
%     >   0.367         7      3.16     -1.21
%     >       7         7         7         7
%     >    2.02         7      3.09      1.63 ]
%     %
%     % remove all samples that are useless
%     ds_finite_features=cosmo_remove_useless_data(ds,2);
%     cosmo_disp(ds_finite_features.samples);
%     > [ 0.862      2.02      3.03         7      3.09      1.63 ]
%
% Notes:
%  - by default, this function removes useless features
%  - data with constant and/or non-finite features is considered 'useless'
%    because they are not helpful in discriminating between conditions of
%    interest
%
% NNO Aug 2014

if nargin<3 || isempty(type), type='all'; end
if nargin<2 || isempty(dim), dim=1; end;

data=ds.samples;
n=size(data,1);

switch type
    case 'finite'
        m=finite(data, dim);
    case 'variable'
        m=variable(data, dim);
    case 'all'
        m=finite(data, dim) & variable(data, dim);
    otherwise
        error('illegal type %s', type);
end

other_dim=3-dim;
ds_useful=cosmo_slice(ds, m, other_dim);

function tf=finite(d, dim)
    tf=all(isfinite(d),dim);

function tf=variable(d, dim)
    switch dim
        case 1
            d_first=d(1,:);
        case 2
            d_first=d(:,1);
    end

tf=sum(bsxfun(@ne, d_first, d), dim)>0 & ~any(isnan(d),dim);


