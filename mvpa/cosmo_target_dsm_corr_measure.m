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
%                  - target dissimilarity matrix of size PxP. It should
%                    have zeros on the diagonal and be symmetric.
%                  - target dissimilarity vector of size Nx1, with
%                    N=P*(P-1)/2 the number of pairs of samples in ds.
%     .metric      (optional) distance metric used in pdist to compute
%                  pair-wise distances between samples in ds. It accepts
%                  any metric supported by pdist (default: 'correlation')
%     .type        (optional) type of correlation between target_dsm and
%                  ds, one of 'Pearson' (default), 'Spearman', or
%                  'Kendall'.
%     .regress_dsm (optional) target dissimilarity matrix or vector (as
%                  .target_dsm) that should be regressed out. If this
%                  option is provided then the output is the partial
%                  correlation between the pairwise distances between
%                  samples in ds and target_dsm, after controlling for the
%                  effect in regress_dsm.
%
%
% Output:
%    ds_sa         Dataset struct with fields:
%      .samples    Scalar correlation value between the pair-wise
%                  distances of the samples in ds and target_dsm.
%      .sa         Struct with field:
%        .labels   {'rho'}
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

    check_input(ds);

    % - compute the pair-wise distance between all dataset samples using
    %   cosmo_pdist

    ds_pdist = cosmo_pdist(ds.samples, params.metric)';

    % number of pairwise distances; should match that of target_dsm_vec
    % below
    npairs_dataset=numel(ds_pdist);

    % get target dsm in vector form
    target_dsm_vec=get_dsm_vec(params,'target_dsm',npairs_dataset);

    % ensure the size of the dataset matches the matrix

    has_regress_dsm=isfield(params,'regress_dsm');
    if has_regress_dsm
        regress_dsm_vec=get_dsm_vec(params,'regress_dsm',npairs_dataset);

        % overwrite
        [ds_pdist(:),target_dsm_vec(:)]=regress_out(ds_pdist,...
                                                target_dsm_vec,...
                                                regress_dsm_vec);
    end


    % >@@>
    % compute correlations between 'pd' and 'target_dsm_vec', store in 'rho'
    rho=cosmo_corr(ds_pdist,target_dsm_vec, params.type);
    % <@@<

    % store results
    ds_sa=struct();
    ds_sa.samples=rho;
    ds_sa.sa.labels={'rho'};
    ds_sa.sa.metric={params.metric};
    ds_sa.sa.type={params.type};


function [ds_resid,target_resid]=regress_out(ds_pdist,...
                                                target_dsm_vec,...
                                                regress_dsm_vec)
    % set up design matrix
    nsamples=size(ds_pdist,1);
    regr=[regress_dsm_vec ones(nsamples,1)];

    % put ds_pdist and target_dsm_vec together
    both=[ds_pdist target_dsm_vec];

    % compute residuals
    both_resid=both-regr*(regr\both);

    ds_resid=both_resid(:,1);
    target_resid=both_resid(:,2);


function dsm_vec=get_dsm_vec(params,name,npairs_dataset)
    % helper funciton to get dsm in vector form
    if ~isfield(params,name)
        error('Missing parameter ''%s''',name);
    end

    dsm=params.(name);

    if isrow(dsm)
        dsm_vec=dsm';
    elseif iscolumn(dsm)
        dsm_vec=dsm;
    else
        % convert square matrix to vector
        dsm_vec=cosmo_squareform(dsm,'tovector')';
    end

    if npairs_dataset ~= numel(dsm_vec),
        error(['Sample size mismatch between dataset (%d pairs) '...
                    'and ''%s'' in vector form (%d pairs)'], ...
                        npairs_dataset,name,numel(dsm_vec));
    end



function check_input(ds)
    % for safety require targets to be 1:N
    has_sa=isstruct(ds) && isfield(ds,'sa');
    if ~has_sa || ~isfield(ds.sa,'targets') || ~isfield(ds,'samples')
        error('Missing field .sa.targets or .samples');
    end

    nsamples=size(ds.samples,1);

    if ~isequal(ds.sa.targets',1:nsamples)
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
