function ds_res=cosmo_cartesian_dim_transfer(ds, dim_label, measure, varargin)
%
%
% Examples:
%     sz='big';
%     train_ds=cosmo_synthetic_dataset('type','timelock','size',sz,'nchunks',5);
%     test_ds=cosmo_synthetic_dataset('type','timelock','size',sz);
%     % set chunks
%     train_ds.sa.chunks(:)=1;
%     test_ds.sa.chunks(:)=2;
%     %
%     % construct the dataset
%     ds=cosmo_stack({train_ds, test_ds});
%     %
%     % make time a sample dimension
%     dim_label='time';
%     ds_time=cosmo_dim_transpose(ds,dim_label,1);
%     %
%     % set measure and its arguments
%     measure=@cosmo_correlation_measure;
%     measure_args=struct();
%     %
%     % run time-by-time generalization analysis
%     cdt_ds=cosmo_cartesian_dim_transfer(ds_time,dim_label,measure,'progress',false);
%     %
%     % the output dataset has no feature dimensions, and
%     % 'train_time' and 'test_time' as sample dimensions
%     cosmo_disp(cdt_ds)
%     > .samples
%     >   [ 0.0454
%     >     0.0388
%     >      0.043
%     >        :
%     >     0.0426
%     >     0.0492
%     >     0.0669 ]@49x1
%     > .sa
%     >   .labels
%     >     { 'corr'
%     >       'corr'
%     >       'corr'
%     >         :
%     >       'corr'
%     >       'corr'
%     >       'corr' }@49x1
%     >   .train_time
%     >     [ 1
%     >       1
%     >       1
%     >       :
%     >       7
%     >       7
%     >       7 ]@49x1
%     >   .test_time
%     >     [ 1
%     >       2
%     >       3
%     >       :
%     >       5
%     >       6
%     >       7 ]@49x1
%     > .a
%     >   .sdim
%     >     .labels
%     >       { 'train_time'  'test_time' }
%     >     .values
%     >       { [  -0.2        [  -0.2
%     >           -0.15          -0.15
%     >            -0.1           -0.1
%     >             :              :
%     >               0              0
%     >            0.05           0.05
%     >             0.1 ]@7x1      0.1 ]@7x1 }
%     >   .fdim
%     >     .values
%     >       {  }
%     >     .labels
%     >       {  }
%     > .fa
%
%     % Searchlight over channels, using LDA classifier generalizing over time
%     sz='big';
%     train_ds=cosmo_synthetic_dataset('type','timelock','size',sz,'nchunks',5);
%     test_ds=cosmo_synthetic_dataset('type','timelock','size',sz);
%     % set chunks
%     train_ds.sa.chunks(:)=1;
%     test_ds.sa.chunks(:)=2;
%     %
%     % construct the dataset
%     ds=cosmo_stack({train_ds, test_ds});
%     %
%     % make time a sample dimension
%     dim_label='time';
%     ds_time=cosmo_dim_transpose(ds,dim_label,1);
%     %
%     % define neighborhood for searchlight analysis over channels
%     chan_nbrhood=cosmo_meeg_chan_neighborhood(ds_time,-10,'planar2cmb');
%     %
%     % set measure and its arguments
%     measure=@cosmo_crossvalidation_measure;
%     measure_args=struct();
%     measure_args.normalization='zscore';
%     measure_args.classifier=@cosmo_classify_lda;
%     %
%     % set options
%     opt=struct();
%     opt.args=measure_args;
%     opt.nbrhood=chan_nbrhood;
%     opt.progress=false;
%     %
%     % for faster execution, use only a few features. Usually one would set
%     % center_ids=[] to use all features
%     opt.center_ids=[3 102];
%     %
%     % run time-by-time generalization analysis
%     cdt_sl_ds=cosmo_cartesian_dim_transfer(ds_time,dim_label,measure,opt);
%     %
%     % the output dataset has 'chan' as feature dimensions, and
%     % 'train_time' and 'test_time' as sample dimensions
%     %
%     % as illustration, the data can be transposed by making train_time and
%     % test_time feature (rather than sample) dimensions
%     cdt_tf_ds=cosmo_dim_transpose(cdt_sl_ds,{'train_time','test_time'},2);
%     %
%     % subsequently the train_time and test_time can be renamed
%     % to freq and time, respectively. Using ft_map2meeg would trick fieldtrip
%     % into thinking this is a chan-freq-time dataset
%     cdt_tf_ds=cosmo_dim_rename(cdt_tf_ds,'train_time','freq');
%     cdt_tf_ds=cosmo_dim_rename(cdt_tf_ds,'test_time','time');
%     cosmo_disp(cdt_tf_ds);
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'chan'
%     >         'freq'
%     >         'time' }
%     >     .values
%     >       { { 'MEG0112+0113'
%     >           'MEG0122+0123'
%     >           'MEG0132+0133'
%     >                 :
%     >           'MEG2622+2623'
%     >           'MEG2632+2633'
%     >           'MEG2642+2643' }@102x1
%     >         [  -0.2
%     >           -0.15
%     >            -0.1
%     >             :
%     >               0
%     >            0.05
%     >             0.1 ]@7x1
%     >         [  -0.2
%     >           -0.15
%     >            -0.1
%     >             :
%     >               0
%     >            0.05
%     >             0.1 ]@7x1            }
%     >   .meeg
%     >     .samples_type
%     >       'timelock'
%     >     .samples_field
%     >       'trial'
%     >     .samples_label
%     >       'rpt'
%     >   .sdim
%     >     .labels
%     >       {  }
%     >     .values
%     >       {  }
%     > .fa
%     >   .chan
%     >     [ 3       102         3  ...  102         3       102 ]@1x98
%     >   .center_ids
%     >     [ 3       102         3  ...  102         3       102 ]@1x98
%     >   .freq
%     >     [ 1         1         1  ...  7         7         7 ]@1x98
%     >   .time
%     >     [ 1         1         2  ...  6         7         7 ]@1x98
%     > .samples
%     >   [ 0.333     0.833     0.333  ...  0.167     0.833       0.5 ]@1x98
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
%     % Searchlight over channels and frequencies, using LDA classifier
%     % generalizing over time
%     sz='big';
%     train_ds=cosmo_synthetic_dataset('type','timefreq','size',sz,'nchunks',5);
%     test_ds=cosmo_synthetic_dataset('type','timefreq','size',sz);
%     % set chunks
%     train_ds.sa.chunks(:)=1;
%     test_ds.sa.chunks(:)=2;
%     %
%     % construct the dataset
%     ds=cosmo_stack({train_ds, test_ds});
%     %
%     % make time a sample dimension
%     dim_label='time';
%     ds_timefreq=cosmo_dim_transpose(ds,dim_label,1);
%     %
%     % define neighborhood for searchlight analysis over channels and
%     % frequencies
%     chan_nbrhood=cosmo_meeg_chan_neighborhood(ds_timefreq,-10,'planar2cmb');
%     freq_nbrhood=cosmo_interval_neighborhood(ds_timefreq,'freq',2);
%     nbrhood=cosmo_neighborhood(ds_timefreq, chan_nbrhood, freq_nbrhood,...
%                                                '-progress',false);
%     %
%     % set measure and its arguments
%     measure=@cosmo_crossvalidation_measure;
%     measure_args=struct();
%     measure_args.normalization='zscore';
%     measure_args.classifier=@cosmo_classify_lda;
%     %
%     % set options
%     opt=struct();
%     opt.args=measure_args;
%     opt.nbrhood=nbrhood;
%     opt.progress=false;
%     %
%     % for faster execution, use only a few features. Usually one would set
%     % center_ids=[] to use all features
%     opt.center_ids=[3 301];
%     %
%     % run time-by-time generalization analysis
%     cdt_sl_ds=cosmo_cartesian_dim_transfer(ds_timefreq,dim_label,measure,opt);
%     %
%     % the output dataset has 'chan' and 'freq' as feature dimensions, and
%     % 'train_time' and 'test_time' as sample dimensions
%     cosmo_disp(cdt_sl_ds);
%     > .a
%     >   .fdim
%     >     .values
%     >       { { 'MEG0112+0113'          [  2
%     >           'MEG0122+0123'             4
%     >           'MEG0132+0133'             6
%     >                 :                    :
%     >           'MEG2622+2623'            10
%     >           'MEG2632+2633'            12
%     >           'MEG2642+2643' }@102x1    14 ]@7x1 }
%     >     .labels
%     >       { 'chan'  'freq' }
%     >   .meeg
%     >     .samples_type
%     >       'freq'
%     >     .samples_field
%     >       'powspctrm'
%     >     .samples_label
%     >       'rpt'
%     >   .sdim
%     >     .labels
%     >       { 'train_time'  'test_time' }
%     >     .values
%     >       { [  -0.2    [  -0.2
%     >           -0.15      -0.15
%     >            -0.1       -0.1
%     >           -0.05      -0.05
%     >               0 ]        0 ] }
%     > .fa
%     >   .chan
%     >     [ 3        97 ]
%     >   .freq
%     >     [ 1         3 ]
%     >   .center_ids
%     >     [ 3       301 ]
%     > .samples
%     >   [   0.5     0.833
%     >     0.333     0.833
%     >     0.667     0.833
%     >       :         :
%     >     0.667     0.667
%     >     0.667       0.5
%     >       0.5     0.333 ]@25x2
%     > .sa
%     >   .labels
%     >     { 'accuracy'
%     >       'accuracy'
%     >       'accuracy'
%     >           :
%     >       'accuracy'
%     >       'accuracy'
%     >       'accuracy' }@25x1
%     >   .train_time
%     >     [ 1
%     >       1
%     >       1
%     >       :
%     >       5
%     >       5
%     >       5 ]@25x1
%     >   .test_time
%     >     [ 1
%     >       2
%     >       3
%     >       :
%     >       3
%     >       4
%     >       5 ]@25x1
%
% NNO Aug 2014


    defaults=struct();
    defaults.args=struct();
    defaults.progress=10;
    defaults.balance_partitions.nsets=1;
    opt=cosmo_structjoin(defaults, varargin);

    % wrapper function that acts like a measure
    cdt_measure=@(x,y) dim_transfer_measure_wrapper(x, dim_label, measure, y);

    if ~isfield(opt, 'nbrhood') || isempty(opt.nbrhood)
        opt.args.progress=opt.progress;
        ds_res=cdt_measure(ds, opt.args);
        ds_res.a.fdim.values=cell(0);
        ds_res.a.fdim.labels=cell(0);
        ds_res.fa=struct();
    else
        ds_res=cosmo_searchlight(ds, cdt_measure, opt);
    end


function res=dim_transfer_measure_wrapper(ds, dim_label, measure, opt)
    [train_sp, test_sp]=get_data_split(ds, dim_label);
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
    if has_dim_label(ds, dim_label, 1)
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

    % see if they are compatible
    stacked=cosmo_stack({cosmo_slice(train_ds,1),cosmo_slice(test_ds,1)});

    if ~has_dim_label(ds, dim_label, 1)
        error('missing dimension label %s for samples', dim_label);
    end

    train_chunk=unique_chunk(train_ds);
    test_chunk=unique_chunk(test_ds);

    if train_chunk~=1 || test_chunk~=2
        error(['dataset must have .sa.chunks set to 1 for the train '...
                'data and to 2 for the test data, but found chunks '...
                'with values %d and %d'], train_chunk, test_chunk);
    end

    train_sp=cosmo_split(train_ds,dim_label,1);
    test_sp=cosmo_split(test_ds,dim_label,1);

    ensure_splits_have_same_size(train_sp, dim_label);
    ensure_splits_have_same_size(test_sp, dim_label);

function ds=single_dim_transfer(train_sp, test_sp, dim_label, measure, opt)
    show_progress=isfield(opt,'progress') && ...
                            ~isempty(opt.progress) && ...
                            opt.progress;
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

    ds.a.sdim.labels=[ds.a.sdim.labels(:);...
                                {train_label; test_label}]';

    train_dim=cosmo_match(x.a.sdim.labels,dim_label);
    test_dim=cosmo_match(y.a.sdim.labels,dim_label);

    ds.a.sdim.values=[ds.a.sdim.values;...
                                x.a.sdim.values{train_dim}(:);...
                                y.a.sdim.values{test_dim}(:)]';


function unq=unique_chunk(ds)
    cosmo_isfield(ds,'sa.chunks',true);

    unq=unique(ds.sa.chunks);
    n=numel(unq);

    if n~=1
        error('%d unique values for .sa.chunks found, expected 1', n);
    end

function ensure_splits_have_same_size(sp, dim_label)
    ns=cellfun(@numel,sp);
    msk=ns~=ns(1);
    if any(msk);
        i=find(msk,1);
        error(['split on %s has different sizes (%d and %d) for '...
            'elements 1 and %d'], dim_label, ns(1), ns(i), i);
    end



