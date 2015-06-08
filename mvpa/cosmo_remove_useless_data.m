function [ds_useful,msk]=cosmo_remove_useless_data(ds, dim, type)
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
%                   default: 'all'
% Output:
%   ds_useful       dataset struct sliced so that useless data along the
%                   dim-th dimension is removed. Data is not considered as
%                   constant if it is not NaN and there is a single row (or
%                   column).
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
%     > [    NaN     -1.05    -0.262         7    -0.209     0.844
%     >    0.584     0.915       Inf         7      2.39      1.86
%     >        7         7         7         7         7         7
%     >   -0.518      1.84     0.482         7      1.39     0.502 ]
%     %
%     % remove all features that are useless
%     ds_useful=cosmo_remove_useless_data(ds);
%     cosmo_disp(ds_useful.samples);
%     > [ -1.05    -0.209     0.844
%     >   0.915      2.39      1.86
%     >       7         7         7
%     >    1.84      1.39     0.502 ]
%     %
%     % remove all features that are constant, and get the logical mask
%     % of the kept features
%     [ds_variable,msk]=cosmo_remove_useless_data(ds,1,'variable');
%     cosmo_disp(ds_variable.samples);
%     > [ -1.05    -0.262    -0.209     0.844
%     >   0.915       Inf      2.39      1.86
%     >       7         7         7         7
%     >    1.84     0.482      1.39     0.502 ]
%     cosmo_disp(msk)
%     > [ false true true false true true ]
%     %
%     % remove all features that are not finite
%     ds_finite=cosmo_remove_useless_data(ds,1,'finite');
%     cosmo_disp(ds_finite.samples);
%     > [ -1.05         7    -0.209     0.844
%     >   0.915         7      2.39      1.86
%     >       7         7         7         7
%     >    1.84         7      1.39     0.502 ]
%     %
%     % remove all samples that are useless
%     ds_finite_features=cosmo_remove_useless_data(ds,2);
%     cosmo_disp(ds_finite_features.samples);
%     > [ -0.518      1.84     0.482         7      1.39     0.502 ]
%     %
%     % illustrate that this function also works on an array directly
%     samples_finite_features=cosmo_remove_useless_data(ds.samples,2);
%     cosmo_disp(samples_finite_features);
%     > [ -0.518      1.84     0.482         7      1.39     0.502 ]
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

if isstruct(ds)
    data=ds.samples;
elseif isnumeric(ds) || islogical(ds)
    data=ds;
else
    error('illegal input: expect array or dataset struct');
end

n=size(data,1);

switch type
    case 'finite'
        msk=finite(data, dim);
    case 'variable'
        msk=variable(data, dim);
    case 'all'
        msk=finite(data, dim) & variable(data, dim);
    otherwise
        error('illegal type %s', type);
end

other_dim=3-dim;
ds_useful=cosmo_slice(ds, msk, other_dim);

function tf=finite(d, dim)
    tf=all(isfinite(d),dim);

function tf=variable(d, dim)
    switch dim
        case 1
            d_first=d(1,:);
        case 2
            d_first=d(:,1);
    end

    tf=~any(isnan(d),dim);
    if size(d,dim)>1
        tf=tf & sum(bsxfun(@ne, d_first, d), dim)>0;
    end

