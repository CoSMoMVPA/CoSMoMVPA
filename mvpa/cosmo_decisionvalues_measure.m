function ds_sa = cosmo_decisionvalues_measure(ds, varargin)

    % deal with input arguments
    opt=cosmo_structjoin(varargin);

    if ~isfield(opt, 'classifier'),
        opt.classifier=@cosmo_classify_naive_bayes;
    end
    classifier = opt.classifier;
    if ~isfield(opt, 'normalization'),
        opt.normalization=[];
    end
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

    ds_sa=struct();
    ds_sa.samples = decisionvalues;
    ds_sa.sa.targets = ds.sa.targets;
    