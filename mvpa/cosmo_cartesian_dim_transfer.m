function ds_res=cosmo_cartesian_dim_transfer(ds, dim_label, measure, varargin)

%     sz='huge';
%     train_ds=cosmo_synthetic_dataset('type','timefreq','size',sz);
%     test_ds=cosmo_synthetic_dataset('type','timefreq','size',sz,'nmodalities',3);
%     train_ds.sa.chunks(:)=1;
%     test_ds.sa.chunks(:)=2;
%
%     measure=@cosmo_correlation_measure;
%     opt=struct();
%     opt.args=struct();
%     opt.args.output='raw';
%     dim_label='time';

    defaults=struct();
    defaults.args=struct();
    defaults.progress=10;
    opt=cosmo_structjoin(defaults, varargin);

    sl_measure=@(x,y) dim_transfer_measure_wrapper(x, dim_label, measure, y);

    if ~isfield(opt, 'nbrhood') || isempty(opt.nbrhood)
        opt.args.progress=opt.progress;
        ds_res=sl_measure(ds, opt.args);
        ds_res.a.fdim.values=cell(0);
        ds_res.a.fdim.labels=cell(0);
        ds_res.fa=struct();
    else
        ds_res=cosmo_searchlight(ds, sl_measure, opt);
    end


function res=dim_transfer_measure_wrapper(ds, dim_label, measure, opt)
    [train_sp, test_sp, is_transposed]=get_data_split(ds, dim_label);

    if isfield(opt,'nbrhood') && is_transposed
        error(['dim_label ''%s'' is a feature dimension, this is '...
                    'incompatible with the ''nbrhood'' option. To '...
                    'use the ''nbrhood'' option, use \n\n'...
                    '  ds_tr=cosmo_dim_transpose(ds, ''%s'', 1)\n\n'...
                    'and use ds_tr as the input for this function'],...
                    dim_label, dim_label);
    end

    res=single_dim_transfer(train_sp, test_sp, dim_label, measure, opt);



function tf=has_dim_label(ds, dim_label, dim)
    infixes='sf';
    infix=infixes(dim);
    if ~cosmo_isfield(ds,{['a.' infix 'dim.labels'],...
                          ['a.' infix 'dim.values'],...
                          [infix 'a.' dim_label]});
        tf=false;
        return;
    end

    labels=ds.a.([infix 'dim']).labels;
    tf=any(cosmo_match({dim_label},labels));

function [dst, is_transposed]=ds_with_sdim(ds, dim_label)
    if has_dim_label(ds, dim_label, 2)
        dst=cosmo_dim_transpose(ds, dim_label, 1);
        is_transposed=true;
    elseif has_dim_label(ds, dim_label, 1)
        is_transposed=false;
        dst=ds;
    else
        error('dim label %s missing in dataset', dim_label);
    end

function [train_sp, test_sp, is_transposed]=get_data_split(ds, dim_label)
    % input can be cell of two datasets, or single dataset with two chunks
    if iscell(ds)
        if numel(ds)~=2
            error('cell input requires two datasets');
        end
        train_ds=ds{1};
        train_ds.sa.chunks(:)=1;

        test_ds=ds{2};
        test_ds.sa.chunks(:)=2;
    else
        sp=cosmo_split(ds,'chunks');
        n=numel(sp);
        if n~=2
            error('dataset must have two unique chunks, found %d', n);
        end
        train_ds=sp{1};
        test_ds=sp{2};
    end

    [train_ds, train_is_transposed]=ds_with_sdim(train_ds, dim_label);
    [test_ds, test_is_transposed]=ds_with_sdim(test_ds, dim_label);
    is_transposed=train_is_transposed || test_is_transposed;

    % see if they are compatible
    cosmo_stack({cosmo_slice(train_ds,1),cosmo_slice(test_ds,1)});

    train_chunk=unique_chunk(train_ds);
    test_chunk=unique_chunk(test_ds);

    if train_chunk==test_chunk
        error(['Dataset share chunk %d, this is not allowed. You may want'...
                'to assign chunks manually, e.g. .sa.chunks(:)=1; for '...
                'the first dataset and .sa.chunks(:)=2; for the second '...
                'dataset'], test_chunk);
    end

    train_sp=cosmo_split(train_ds,dim_label,1);
    test_sp=cosmo_split(test_ds,dim_label,1);

    ensure_same_size(train_sp, dim_label);
    ensure_same_size(test_sp, dim_label);

function ds=single_dim_transfer(train_sp, test_sp, dim_label, measure, opt)
    show_progress=isfield(opt,'progress') && ~isempty(progress);
    if show_progress
        progress_step=opt.progress;
    end

    ntrain=numel(train_sp);
    ntest=numel(test_sp);

    train_label=['train_' dim_label];
    test_label=['test_' dim_label];

    res=cell(1,ntrain*ntest);

    pos=0;

    if show_progress
        prev_msg='';
        clock_start=clock();
    end


    for k=1:ntrain
        x=train_sp{k};
        x_sa=x.sa.(dim_label);

        for j=1:ntest
            y=test_sp{j};
            y_sa=y.sa.(dim_label);

            is_first_iteration=pos==0;
            xy=cosmo_stack({x,y},1,is_first_iteration);

            if is_first_iteration
                test_chunk=y.sa.chunks(1);
                assert(all(test_chunk==y.sa.chunks));

                if cosmo_isfield(opt,'partitions')
                    error(['partitions cannot be specified in this '...
                            'function, because it assigns the '...
                            'partitions itself']);
                end


                opt.partitions=cosmo_nchoosek_partitioner(xy,1,...
                                            'chunks',test_chunk);
                opt.check_partitions=false;
            end

            % apply measure
            v=measure(xy, opt);

            % ensure they have the same size
            nsamples=size(v.samples,1);
            if pos==0
                nsamples_first=nsamples;
            elseif nsamples~=nsamples_first
                error('result %d must have %d samples, found %d',...
                        pos+1, nsamples_first, nsamples);
            end



            v.sa.(train_label)=repmat(x_sa(1),nsamples,1);
            v.sa.(test_label)=repmat(y_sa(1),nsamples,1);

            pos=pos+1;
            res{pos}=v;
        end
        if show_progress && (k<10 || mod(k, progress_step)==0)
            prev_msg=cosmo_show_progress(clock_start,k/ntrain,'',prev_msg);
        end
    end

    ds=cosmo_stack(res,1);
    if ~all(cosmo_isfield(ds,{'a.sdim.labels','a.sdim.values'}));
        ds.a.sdim.labels=cell(0);
        ds.a.sdim.values=cell(0);
    end

    ds.a.sdim.labels=[ds.a.sdim.labels,...
                                {train_label, test_label}];

    train_dim=cosmo_match(x.a.sdim.labels,dim_label);
    test_dim=cosmo_match(y.a.sdim.labels,dim_label);

    ds.a.sdim.values=[ds.a.sdim.values,...
                                x.a.sdim.values(train_dim),...
                                y.a.sdim.values(test_dim)];


function unq=unique_chunk(ds)
    cosmo_isfield(ds,'sa.chunks',true);

    unq=unique(ds.sa.chunks);
    n=numel(unq);

    if n~=1
        error('%d unique values for .sa.chunks found, expected 1', n);
    end

function ensure_same_size(sp, dim_label)
    ns=cellfun(@numel,sp);
    msk=ns~=ns(1);
    if any(msk);
        i=find(msk,1);
        error(['split on %s has different sizes (%d and %d) for '...
            'elements 1 and %d'], dim_label, ns(1), ns(i), i);
    end



