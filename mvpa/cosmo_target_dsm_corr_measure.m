function ds_sa = cosmo_target_dsm_corr_measure(ds, varargin)
% measure correlation with target dissimilarity matrix
%
% ds_sa = cosmo_target_dsm_corr_measure(dataset, args)
%
% Inputs:
%   ds             dataset struct with field .samples PxQ for P samples and
%                  Q features
%   args           struct with fields:
%     .target_dsm  Either:
%                  - target dissimilarity matrix of size PxP. It should have
%                    zeros on the diagonal and be symmetric.
%                  - target dissimilarity vector of size Nx1, with
%                    N=P*(P-1)/2 the number of pairs of samples in ds.
%     .metric      Distance metric used in pdist to compute pair-wise
%                  distances between samples in ds. It accepts any
%                  metric supported by pdist (default: 'correlation')
%     .type        Type of correlation between target_dsm and ds,
%                  one of 'Pearson' (default), 'Spearman', or 'Kendall'
%
%
% Output:
%    ds_sa           Dataset struct with fields:
%      .samples      Scalar correlation value
%      .sa           Struct with field:
%        .labels     {'rho'}
%
% Examples:
%     % generate synthetic dataset with 6 classes (conditions),
%     % one sample per class
%     ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
%     %
%     % create target dissimilarity matrix to test whether
%     % - class 1 and 2 are similar (and different from classes 3-6)
%     % - class 3 and 4 are similar (and different from classes 1,2,5,6)
%     % - class 5 and 6 are similar (and different from classes 1-4)
%     target_dsm=1-kron(eye(3),ones(2));
%     %
%     % show the target dissimilarity matrix
%     cosmo_disp(target_dsm);
%     > [ 0         0         1         1         1         1
%     >   0         0         1         1         1         1
%     >   1         1         0         0         1         1
%     >   1         1         0         0         1         1
%     >   1         1         1         1         0         0
%     >   1         1         1         1         0         0 ]
%     %
%     % compute similarity between pairw-wise similarity of the
%     % patterns in the dataset and the target dissimilarity matrix
%     dcm_ds=cosmo_target_dsm_corr_measure(ds,'target_dsm',target_dsm);
%     %
%     % Pearson correlation is about 0.56
%     cosmo_disp(dcm_ds)
%     > .samples
%     >   [ 0.562 ]
%     > .sa
%     >   .labels
%     >     { 'rho' }
%     >   .metric
%     >     { 'correlation' }
%     >   .type
%     >     { 'Pearson' }
%
% Notes
%
% ACC August 2013, NNO Jan 2015

    % process input arguments
    params=cosmo_structjoin('type','Pearson',... % set default
                            'metric','correlation',...
                            varargin);

    if ~isfield(params,'target_dsm')
        error('Missing parameter ''target_dsm''');
    end

    nsamples=size(ds.samples,1);
    % for safety require targets to be 1:N
    has_sa=isfield(ds,'sa');
    if ~has_sa || ~isfield(ds.sa,'targets')
        error('Missing field .sa.targets');
    elseif ~isequal(ds.sa.targets',1:nsamples)
        msg=sprintf('.sa.targets must be (1:%d)''',nsamples);
        if isequal(unique(ds.sa.targets),(1:nsamples)');
            msg=sprintf(['%s\nMultiple samples with the same chunks '...
                            'can be averaged using cosmo_fx'],msg);
        else
            msg=sprintf(['%s\nConsider setting .sa.chunks to q, where '...
                            '[~,~,q]=unique(ds.sa.targets)',msg]);
        end
        error(msg);
    end

    % - compute the pair-wise distance between all dataset samples using
    %   cosmo_pdist and store in 'pd'
    % >@@>
    pd = cosmo_pdist(ds.samples, params.metric);
    % <@@<

    target_dsm=params.target_dsm;

    if isvector(target_dsm)
        target_dsm_vec=target_dsm;
    else
        % convert square matrix to vector
        target_dsm_vec=cosmo_squareform(params.target_dsm);
    end
        % target_dsm is a vector

    if numel(pd) ~= numel(target_dsm_vec),
        error(['Sample size mismatch between dataset (%d) '...
                    'and target dsm in vector form (%d)'], ...
                        numel(pd), numel(target_dsm_vec));
    end

    % >@@>
    % compute correlations between 'pd' and 'sf', store in 'rho'
    rho=cosmo_corr(pd(:),target_dsm_vec(:), params.type);
    % <@@<

    % store results
    ds_sa=struct();
    ds_sa.samples=rho;
    ds_sa.sa.labels={'rho'};
    ds_sa.sa.metric={params.metric};
    ds_sa.sa.type={params.type};
