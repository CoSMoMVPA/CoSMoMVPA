function ds_sa = cosmo_correlatedecisionvalues_measure(ds, varargin)
    
    % deal with input arguments
    opt=cosmo_structjoin(varargin);

    if ~isfield(opt, 'targetvalues')
        error('targetvalues must be provided')
    end
    targetvalues=opt.targetvalues;
    if size(targetvalues,1)~=size(ds.samples,1)
        error('targetvalues must have the same number of observations as ds')
    end
    if ~isfield(opt, 'classifier'),
        opt.classifier=@cosmo_classify_naive_bayes;
    end
    classifier = opt.classifier;
    if ~isfield(opt, 'normalization'),
        opt.normalization=[];
    end
    if ~isfield(opt, 'correlationtype'),
        opt.correlationtype='Spearman';
    end
    correlationtype=opt.correlationtype;
    if ~isempty(opt.normalization);
        normalization=opt.normalization;
        opt.autoscale=false; % disable for {matlab,lib}svm classifiers
    else
        normalization=[];
    end
    
    if all(isfield(opt, {'pca_explained_count','pca_explained_ratio'}))
            error(['pca_explained_count and pca_explained_ratio are ' ...
                'mutually exclusive'])
    elseif isfield(opt, 'pca_explained_count');
        arg_pca='pca_explained_count';
        arg_pca_value=opt.pca_explained_count;
    elseif isfield(opt, 'pca_explained_ratio');
        arg_pca='pca_explained_ratio';
        arg_pca_value=opt.pca_explained_ratio;
    else
        arg_pca=[];
    end

    train_targets=ds.sa.targets;
    train_data = ds.samples;
    
    % apply pca
    if ~isempty(arg_pca)
        [train_data,pca_params]=cosmo_pca(train_data,...
                arg_pca,arg_pca_value);
    end
    % apply normalization
    if ~isempty(normalization)
        [train_data,params]=cosmo_normalize(train_data,normalization);
    end
    [unused,decisionvalues] = classifier(train_data, train_targets, train_data, opt);

    corr_all = corr(decisionvalues,targetvalues,'type',correlationtype);
    corr_0 = corr(decisionvalues(train_targets==0),...
        targetvalues(train_targets==0),'type',correlationtype);
    corr_1 = corr(decisionvalues(train_targets==1),...
        targetvalues(train_targets==1),'type',correlationtype);
    
    ds_sa=struct();
    ds_sa.samples = [corr_all;corr_0;corr_1];
    ds_sa.sa.label = {'correlation_all','correlation_category_0',...
        'correlation_category_1'}';
    ds_sa.sa.category = [-1;0;1];
    
    