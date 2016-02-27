function d=cosmo_pdist(x, distance)
% compute pair-wise distance between samples in a matrix
%
% d=cosmo_pdist(x[, distance])
%
% Inputs:
%   x            PxM matrix for P samples and M features
%   distance     distance metric: one of 'euclidean' (default),
%                'correlation' (computing one-minus-correlation), or any
%                other metric supported by matlab's built-in 'pdist'
%
% Outputs:
%   d            1xN row vector with pairwise distances, where N=M*(M-1),
%                containing the distances of the lower diagonal of the
%                distance matrix
%
% Examples:
%     data=[1 4 3; 2 2 3; 4 2 0;0 1 1];
%     % compute pair-wise distances with euclidean distance metric.
%     % since there are 4 samples, there are 4*3/2=6 pairs of samples.
%     cosmo_pdist(data)
%     > 2.2361    4.6904    3.7417    3.6056    3.0000    4.2426
%     cosmo_pdist(data,'euclidean')
%     > 2.2361    4.6904    3.7417    3.6056    3.0000    4.2426
%     % compute distances with one-minus-correlation distance metric
%     cosmo_pdist(data,'correlation')
%     > 0.8110    1.6547    0.0551    1.8660    0.5000    1.8660
%
% Notes:
%   - this function provides a native implementation for 'euclidean' and
%     'correlation'; other distance metrics require the pdist function
%     supplied in the matlab stats toolbox, or the octave statistics
%     package
%   - the rationale for providing this function is to support pair-wise
%     distances on platforms without the stats toolbox
%   - to compute pair-wise distances on a dataset struct, use
%     cosmo_dissimilarity_matrix_measure
%   - the output of this function can be given to [cosmo_]squareform to
%     recreate a PxP distance matrix
%
% See also: cosmo_dissimilarity_matrix_measure, cosmo_squareform
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2 || isempty(distance), distance='euclidean'; end

    ns=size(x,1);
    d=zeros(1,ns*(ns-1)/2);

    switch distance
        case 'euclidean'
            pos=0;
            for k=1:ns
                ji=((k+1):ns);
                nj=numel(ji);
                idxs=pos+(1:nj);

                delta=bsxfun(@minus,x(k,:),x(ji,:));
                d_idxs=sqrt(sum(delta.^2,2));

                d(idxs)=d_idxs;
                pos=pos+nj;
            end

        case 'correlation'
            % it's faster to compute all correlations that just the lower
            % diagonal
            dfull=cosmo_corr(x');
            ns_rng=1:ns;

            % make diagonal mask
            msk=bsxfun(@gt,ns_rng',ns_rng);
            d=1-dfull(msk)';


        otherwise
            is_octave=cosmo_wtf('is_octave');
            if is_octave || cosmo_check_external('@stats',false)
                d=pdist(x, distance);
            else
                error(['Matlab requires the stats toolbox for distance '...
                            'metric %s'], distance);
            end

    end

