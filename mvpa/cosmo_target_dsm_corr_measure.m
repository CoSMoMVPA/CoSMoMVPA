function ds_sa = cosmo_target_dsm_corr_measure(ds, varargin)
% measure correlation with target dissimilarity matrix
%
% ds_sa = cosmo_target_dsm_corr_measure(dataset, args)
%
% Inputs:
%   ds             dataset struct with field .samples PxQ for P samples and
%                  Q features
%   args           struct with fields:
%     .target_dsm  (optional) Either:
%                  - target dissimilarity matrix of size PxP. It should
%                    have zeros on the diagonal and be symmetric.
%                  - target dissimilarity vector of size Nx1, with
%                    N=P*(P-1)/2 the number of pairs of samples in ds.
%                  This option is mutually exclusive with the 'glm_dsm'
%                  option
%     .metric      (optional) distance metric used in pdist to compute
%                  pair-wise distances between samples in ds. It accepts
%                  any metric supported by pdist (default: 'correlation')
%     .type        (optional) type of correlation between target_dsm and
%                  ds, one of 'Pearson' (default), 'Spearman', or
%                  'Kendall'. If the 'regress_dsm' option is used, then the
%                  specified correlation type is used for the partial
%                  correlaton computation.
%     .regress_dsm (optional) target dissimilarity matrix or vector (as
%                  .target_dsm), or a cell with matrices or vectors, that
%                  should be regressed out. If this option is provided then
%                  the output is the partial correlation between the
%                  pairwise distances between samples in ds and target_dsm,
%                  after controlling for the effect of the matrix
%                  (or matrices) in regress_dsm. (Using this option yields
%                  similar behaviour as the Matlab function
%                  'partial_corr').
%                  When using this option, the 'type' option cannot be
%                  set to 'Kendall'.
%     .glm_dsm     (optional) cell with model dissimilarity matrices or
%                  vectors (as .target_dsm) for using a general linear
%                  model to get regression coefficients for each element in
%                  .glm_dsm. Both the input data and the dissimilarity
%                  matrices are z-scored before estimating the regression
%                  coefficients.
%                  This option is required when 'target_dsm' is not
%                  provided; it cannot cannot used together with the
%                  'target_dsm' or 'regress_dsm' options.
%                  When using this option, the 'type' option cannot be
%                  set to 'Spearman' or 'Kendall'.
%                  For this option, the output has as many rows (samples)
%                  as there are elements (dissimilarity matrices) in
%                  .glm_dsm.
%     .center_data If set to true, then the mean of each feature (column in
%                  ds.samples) is subtracted from each column prior to
%                  computing the pairwise distances for all samples in ds.
%                  This is generally recommended but is not the default in
%                  order to avoid breaking behavaiour from earlier
%                  versions. For a rationale why this is recommendable, see
%                  the Diedrichsen & Kriegeskorte article (below in
%                  references)
%                  Default: false
%
% Output:
%    ds_sa         Dataset struct with fields:
%      .samples    Scalar correlation value between the pair-wise
%                  distances of the samples in ds and target_dsm; or
%                  (when 'glm_dsms' is supplied) a column vector with
%                  normalized beta coefficients. These values
%                  are untransformed (e.g. there is no Fisher transform).
%      .sa         Struct with field:
%        .labels   {'rho'}; or (when 'glm_dsm' is supplied) a cell
%                  {'beta1','beta2',...}.
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
%     %|| [ 0         0         1         1         1         1
%     %||   0         0         1         1         1         1
%     %||   1         1         0         0         1         1
%     %||   1         1         0         0         1         1
%     %||   1         1         1         1         0         0
%     %||   1         1         1         1         0         0 ]
%     %
%     % compute similarity between pairw-wise similarity of the
%     % patterns in the dataset and the target dissimilarity matrix
%     dcm_ds=cosmo_target_dsm_corr_measure(ds,'target_dsm',target_dsm);
%     %
%     % Pearson correlation is about 0.56
%     cosmo_disp(dcm_ds)
%     %|| .samples
%     %||   [ 0.562 ]
%     %|| .sa
%     %||   .labels
%     %||     { 'rho' }
%     %||   .metric
%     %||     { 'correlation' }
%     %||   .type
%     %||     { 'Pearson' }
%     %
%     % do not consider classses 3 and 5
%     target_dsm([3,5],:)=NaN;
%     target_dsm(:,[3,5])=NaN;
%     target_dsm(3,3)=0;
%     target_dsm(5,5)=0;
%     %
%     % show the updated target dissimilarity matrix
%     cosmo_disp(target_dsm);
%     %|| [   0         0       NaN         1       NaN         1
%     %||     0         0       NaN         1       NaN         1
%     %||   NaN       NaN         0       NaN       NaN       NaN
%     %||     1         1       NaN         0       NaN         1
%     %||   NaN       NaN       NaN       NaN         0       NaN
%     %||     1         1       NaN         1       NaN         0 ]
%     %
%     % compute similarity between pairw-wise similarity of the
%     % patterns in the dataset and the target dissimilarity matrix
%     dcm_ds=cosmo_target_dsm_corr_measure(ds,'target_dsm',target_dsm);
%     %
%     % Correlation is different because classes 3 and 5 were left out
%     cosmo_disp(dcm_ds)
%     %|| .samples
%     %||   [ 0.705 ]
%     %|| .sa
%     %||   .labels
%     %||     { 'rho' }
%     %||   .metric
%     %||     { 'correlation' }
%     %||   .type
%     %||     { 'Pearson' }
%
%
%
% Notes:
%   - for group analysis, correlations can be fisher-transformed
%     through:
%       dcm_ds.samples=atanh(dcm_ds.samples)
%   - it is recommended to set the 'center_data' to true when using
%     the default 'correlation' metric, as this removes a main effect
%     common to all samples; but note that this option is disabled by
%     default due to historical reasons.
%   - elements in the *_dsm dissimilarity matrices can have NaNs, in which
%     case their value, as well as the corresponding location in the
%     dataset's samples, are ignored. Masking is done prior to z-score
%     normalization.
%
% Reference:
%   - Diedrichsen, J., & Kriegeskorte, N. (2017). Representational
%     models: A common framework for understanding encoding,
%     pattern-component, and representational-similarity analysis.
%     PLoS computational biology, 13(4), e1005508.
%
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % process input arguments
    params=cosmo_structjoin('type','Pearson',...
                            'metric','correlation',...
                            'center_data',false,...
                            varargin);

    check_input(ds);
    check_params(params);

    % - compute the pair-wise distance between all dataset samples using
    %   cosmo_pdist

    samples=ds.samples;
    if params.center_data
        samples=bsxfun(@minus,samples,mean(samples,1));
    end

    samples_pdist = cosmo_pdist(samples, params.metric)';

    has_model_dsms=isfield(params,'glm_dsm');

    if has_model_dsms
        ds_sa=linear_regression_dsm(samples_pdist, params);
    else
        ds_sa=correlation_dsm(samples_pdist,params);
    end

    check_output(ds,ds_sa);

function check_output(input_ds,output_ds_sa)
    if any(isnan(output_ds_sa.samples))
        if any(isnan(input_ds.samples(:)))
            msg=['Input dataset has NaN values, which results in '...
                    'NaN values in the output. Consider masking the '...
                    'dataset to remove NaN values'];
        elseif any(var(input_ds.samples)==0)
            msg=['Input dataset has constant or infinite features, ',...
                    'which results in NaN values in the output. '...
                    'Consider masking the dataset to remove constant '...
                    'or non-finite features, for example using '...
                    'cosmo_remove_useless_data'];
        else
            msg=['Output has NaN values, even though the input does '...
                    'not. This can be due to the presence of constant '...
                    'features and/or non-finite values in the input, '...
                    'and/or target similarity structures with constant '...
                    'and/of non-finite data. When in doubt, please '...
                    'contact the CoSMoMVPA developers'];
        end
        cosmo_warning(msg);
    end


function ds_sa=correlation_dsm(samples_pdist,params)
    npairs_dataset=numel(samples_pdist);

    % get target dsm in vector form
    [target_dsm_vec,target_msk]=get_dsm_vec_from_struct(params,...
                                                'target_dsm',...
                                                npairs_dataset);

    if ~isempty(target_msk)
        samples_pdist=samples_pdist(target_msk);
    end


    % ensure the size of the dataset matches the matrix
    has_regress_dsm=isfield(params,'regress_dsm');
    if has_regress_dsm
        [regress_dsm_mat,regress_msk]=get_dsm_mat_from_vector_or_cell(...
                                                    params.regress_dsm,...
                                                    npairs_dataset);

        if ~isequal(target_msk,regress_msk)
            error(['NaN mask non-match between ''target_dsm'' '...
                    'and ''regress_dsm''']);
        end

        [samples_pdist(:),target_dsm_vec(:)]=regress_out(...
                                                samples_pdist,...
                                                target_dsm_vec,...
                                                regress_dsm_mat,...
                                                params.type);
        % regressed out samples are already based on Spearman correlations,
        % so use Pearson for the final correlation computation
        corr_type='Pearson';
    else
        corr_type=params.type;
    end


    rho=cosmo_corr(samples_pdist,target_dsm_vec,corr_type);

    % store results
    ds_sa=struct();
    ds_sa.samples=rho;
    ds_sa.sa.labels={'rho'};
    ds_sa.sa.metric={params.metric};
    ds_sa.sa.type={params.type};


function ds_sa=linear_regression_dsm(samples_pdist, params)
    if ~strcmp(params.type,'Pearson')
        error(['For linear regression, only ''Pearson'' is '...
                'currently allowed']);
    end
    npairs_dataset=numel(samples_pdist);

    [dsm_mat,msk]=get_dsm_mat_from_vector_or_cell(params.glm_dsm,...
                                                npairs_dataset);

    % normalize matrices
    dsm_mat_zscore=cosmo_normalize(dsm_mat,'zscore');


    if ~isempty(msk)
        samples_pdist=samples_pdist(msk);
    end

    % normalize data
    samples_pdist_zscore=cosmo_normalize(samples_pdist(:),'zscore');

    % estimate betas based on masked samples
    betas=dsm_mat_zscore \ samples_pdist_zscore;

    % construct labels
    nvec=size(dsm_mat_zscore,2);
    labels=cell(nvec,1);
    for k=1:nvec
        labels{k}=sprintf('beta%d', k);
    end

    ds_sa=struct();
    ds_sa.samples=betas;
    ds_sa.sa.labels=labels;
    ds_sa.sa.metric=repmat({params.metric},nvec,1);


function [ds_resid,target_resid]=regress_out(ds_pdist,...
                                                target_dsm_vec,...
                                                regress_dsm_mat,...
                                                partial_corr_type)

    if strcmp(partial_corr_type,'Spearman')
        % use ranks of the dissimilarity matrices
        ds_pdist=cosmo_tiedrank(ds_pdist,1);
        target_dsm_vec=cosmo_tiedrank(target_dsm_vec,1);
        regress_dsm_mat=cosmo_tiedrank(regress_dsm_mat,1);
    elseif strcmp(partial_corr_type,'Kendall')
        error('Kendall cannot be used with the ''regress_dsm'' option');
    end

    % set up design matrix
    nsamples=size(ds_pdist,1);
    regr=[regress_dsm_mat ones(nsamples,1)];

    % put ds_pdist and target_dsm_vec together
    both=[ds_pdist target_dsm_vec];

    % compute residuals
    both_resid=both-regr*(regr\both);

    ds_resid=both_resid(:,1);
    target_resid=both_resid(:,2);

function [dsm_mat,common_msk]=get_dsm_mat_from_vector_or_cell(dsm_cell, ...
                                                        npairs_dataset)
    if isnumeric(dsm_cell)
        dsm_cell={dsm_cell};
    elseif ~iscell(dsm_cell)
        error('dsm inputs must be provided in a cell');
    end

    n=numel(dsm_cell);
    for k=1:n
        name=sprintf('.model_dsms{%d}',k);
        [vec,msk_k]=get_dsm_vec(dsm_cell{k},npairs_dataset,name);

        if k==1
            nrows=numel(vec);
            dsm_mat=zeros(nrows,n);

            common_msk=msk_k;
        end


        if ~isempty(msk_k) && k~=1 && ~isequal(common_msk,msk_k)
            error('DSMs NaN mask mismatch for matrices %d and %d',...
                        1, k);
        end

        dsm_mat(:,k)=vec;
    end

function [dsm_vec,msk]=get_dsm_vec_from_struct(params,name,npairs_dataset)
    % helper funciton to get dsm in vector form
    if ~isfield(params,name)
        error('Missing parameter ''%s''',name);
    end

    dsm=params.(name);
    [dsm_vec,msk]=get_dsm_vec(dsm, npairs_dataset, ['''' name '''']);


function [dsm_vec,msk]=get_dsm_vec(dsm,npairs_dataset,name)
    % helper function to get dsm in column vector form
    if ~isnumeric(dsm)
        error('dsm inputs must be numeric, found %s', class(dsm));
    end

    sz=size(dsm);

    if sz(1)==1
        dsm_vec=dsm';
    elseif sz(2)==1
        dsm_vec=dsm;
    else
        % convert square matrix to vector
        dsm_vec=cosmo_squareform(dsm,'tovector')';
    end

    if npairs_dataset ~= numel(dsm_vec),
        error(['Sample size mismatch between dataset (%d pairs) '...
                    'and %s in vector form (%d pairs)'], ...
                        npairs_dataset,name,numel(dsm_vec));
    end

    msk=[];

    nan_msk=isnan(dsm_vec);
    if any(nan_msk)
        % apply mask
        msk=~nan_msk;
        dsm_vec=dsm_vec(msk);
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

function check_params(params)
    if isfield(params,'glm_dsm')
        if isfield(params,'regress_dsm') || isfield(params,'target_dsm')
            error(['''glm_dsm'' cannot be used with ''regress_dsm'''...
                    'or ''target_dsm''']);
        end
    elseif ~isfield(params,'target_dsm')
        error('''target_dsm'' or ''glm_dsm'' option is required');
    end

    ensure_is_valid_correlation(params,'type');


function ensure_is_valid_correlation(params,key)
    value=params.(key);

    allowed_types={'Spearman','Pearson','Kendall'};

    if ~(ischar(value) ...
            && any(strcmp(value,allowed_types)))
        error('''%s'' argument must be one of: ''%s''',...
                key,cosmo_strjoin(allowed_types,'''%s'', '));
    end

