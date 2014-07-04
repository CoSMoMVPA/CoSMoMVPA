function ds=cosmo_normalize(ds, norm_type, dim)
% normalize a dataset by demeaning or z-scoring
%
% ds=cosmo_normalize(ds, norm_type, dim)
%
% Inputs
%   ds            a dataset struct with field .samples of size PxQ, or a
%                 numeric array of that size
%   norm_type     either "demean" or "zscore". Id dim is not provied, it 
%                 can also be one of these strings concatenated with one 
%                 of "1" or "S" (setting dim==1) or to "2" or "F" 
%                 (setting dim==2).
%   dim           1 or 2, indicating along with dimension of ds to 
%                 normalize. 
%
% Output
%   ds_norm       a dataset struct similar to ds, but with .samples data
%                 normalized. If the input was a numeric array then ds_norm
%                 is a numeric array as well.
%                 The output has zero mean along the dim-th dimension,
%                 and if norm_type is set to "zscore" then it has variance
%                 of 1 along the dim-th dimension as well.
%
% Examples:
%     ds=struct();
%     ds.samples=reshape(1:12,3,4)*2;
%     cosmo_disp(ds);
%     > .samples
%     >   [ 2         8        14        20
%     >     4        10        16        22
%     >     6        12        18        24 ]
%     %
%     % demean along first dimension
%     dsn=cosmo_normalize(ds,'demean',1);
%     cosmo_disp(dsn);
%     > .samples
%     >   [ -2        -2        -2        -2
%     >      0         0         0         0
%     >      2         2         2         2 ]
%     %
%     % demean along second dimension
%     dsn=cosmo_normalize(ds,'demean',2);
%     cosmo_disp(dsn);
%     > .samples
%     >   [ -9        -3         3         9
%     >     -9        -3         3         9
%     >     -9        -3         3         9 ]
%     %
%     % z-score along first dimension
%     dsn=cosmo_normalize(ds,'zscore',1);
%     cosmo_disp(dsn);
%     > .samples
%     >   [ -1        -1        -1        -1
%     >      0         0         0         0
%     >      1         1         1         1 ]
%     %
%     % z-score along second dimension
%     dsn=cosmo_normalize(ds,'zscore',2);
%     cosmo_disp(dsn);
%     > .samples
%     >   [ -1.16    -0.387     0.387      1.16
%     >     -1.16    -0.387     0.387      1.16
%     >     -1.16    -0.387     0.387      1.16 ]
%     % do the same as the above, but now specify the dimension 
%     % in the 2nd argument
%     > a
%     dsn=cosmo_normalize(ds,'zscoreS');
%     cosmo_disp(dsn);
%     > .samples
%     >   [ -1        -1        -1        -1
%     >      0         0         0         0
%     >      1         1         1         1 ]
%     dsn=cosmo_normalize(ds,'zscoreF');
%     cosmo_disp(dsn);
%     > .samples
%     >   [ -1.16    -0.387     0.387      1.16
%     >     -1.16    -0.387     0.387      1.16
%     >     -1.16    -0.387     0.387      1.16 ]
%   
% NNO Oc 2013


if isempty(norm_type) || strcmp(norm_type,'none')
    return;
end

has_dim=nargin>=3;

if ~has_dim
    dim=0;
    postfixes={'1S','2F'};
    for k=1:numel(postfixes)
        postfix=postfixes{k};
        if any(norm_type(end)==postfix)
            dim=k;
            norm_type=norm_type(1:(end-1));
            break
        end
    end
end

if all(dim~=[1,2])
    error(['Unknown dimension: should be 1 or 2, or norm_type should '...
           'end with one of "1", "2", "S", or "F"']);
       
end

is_ds=isstruct(ds) && isfield(ds,'samples');

if is_ds
    samples=ds.samples;
else
    samples=ds;
end

mu=mean(samples,dim);

switch norm_type
    case 'demean'
        samples=bsxfun(@minus,samples,mu);
    case 'zscore'
        sigma=std(samples,[],dim);
        samples=bsxfun(@rdivide,bsxfun(@minus,samples,mu),sigma);
    otherwise
        error('Unsupported normalization: %s', norm_type);
        
end
    
if is_ds
    ds.samples=samples;
else
    ds=samples;
end