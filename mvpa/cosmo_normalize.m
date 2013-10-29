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
% Example:
%   d=randn(3,5);
%   e=cosmo_normalize(d,'demean1')
%   mean(e,1) 
%   > 1.0e-15 * [0.0278 0 -0.0370 -0.0093 -0.1480]
%   e2=cosmo_normalize(d,'zscoreF')
%   mean(e2,1)
%   > [0.4319 -0.7906 0.8651 0.4190 -0.9254]
%   mean(e2,2)'
%   > [0 0 1.526557e-17]
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