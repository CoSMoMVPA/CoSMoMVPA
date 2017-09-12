function test_suite=test_meeg_io()
% tests for MEEG input/output
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_meeg_ft_dataset()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_meeg_dataset(varargin{:}),'');

    dimords=get_ft_dimords();
    n=numel(dimords);
    for k=1:n
        dimord=dimords{k};
        [ft,fdim,data_label]=generate_ft_struct(dimord);
        ds=cosmo_meeg_dataset(ft);
        assertEqual(ds.a.fdim,fdim);

        [nsamples,nfeatures]=size(ds.samples);

        % check feature sizes
        fdim_sizes=cellfun(@numel,fdim.values);
        assertEqual(prod(fdim_sizes),nfeatures);

        % check sample size
        data=ft.(data_label);
        data_size=size(data);
        has_rpt=nsamples>1;
        if has_rpt
            assertEqual(data_size(2:end)',fdim_sizes);
        else
            assertEqual(data_size',fdim_sizes);
        end

        assertElementsAlmostEqual(data(:),ds.samples(:));

        ds2=cosmo_slice(ds,randperm(nfeatures),2);
        ft2=cosmo_map2meeg(ds2);

        if isfield(ft,'cfg')
            ft=rmfield(ft,'cfg');
        end

        if isfield(ft,'avg') && isfield(ft,'trial')
            ft=rmfield(ft,'avg');
        end

        assertEqual(ft,ft2);

        % wrong size trialinfo should not store trialinfo
        assertTrue(isfield(ds2.sa,'trialinfo'));
        ft.trialinfo=[1;2];
        ds3=cosmo_meeg_dataset(ft);
        assertFalse(isfield(ds3.sa,'trialinfo'));
    end

    aet(struct());
    aet(struct('avg',1));
    aet(struct('avg',1,'dimord','rpt_foo'));

function test_meeg_ft_dataset_trials()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_meeg_dataset(varargin{:}),'');

    dimords=get_ft_dimords();
    n=numel(dimords);
    for k=1:n
        dimord=dimords{k};
        ft=generate_ft_struct(dimord);
        ds=cosmo_meeg_dataset(ft);

        % check subset of trials option
        ntrials=size(ds.samples,1);
        trial_idx=ceil(rand(1,2)*ntrials);
        ds_single_trial=cosmo_meeg_dataset(ft,...
                                    'trials',trial_idx);
        assertEqual(cosmo_slice(ds,trial_idx),ds_single_trial);
        ds_single_trial=cosmo_meeg_dataset(ft,...
                                    cosmo_structjoin('trials',trial_idx));
        assertEqual(cosmo_slice(ds,trial_idx),ds_single_trial);

        illegal_args={ntrials+1,0,struct,cell(1,0),'foo',true,1.5};
        for j=1:numel(illegal_args)
            arg=illegal_args{j};
            aet(ft,'trials',arg);
        end
    end



function test_synthetic_meeg_dataset()
    combis=cosmo_cartprod({{'timelock','timefreq','source'},...
                            {'tiny','small','normal','big','huge'}});
    for k=1:4:size(combis,1)
        ds=cosmo_synthetic_dataset('type',combis{k,1},...
                                        'size',combis{k,2});

        ft=cosmo_map2meeg(ds);
        ds2=cosmo_meeg_dataset(ft);
        assertEqual(ds.samples,ds2.samples);
        assertEqual(ds.fa,ds2.fa);
        assertEqual(ds.a.meeg.samples_field,ds2.a.meeg.samples_field);
    end

    ds2=cosmo_meeg_dataset(ds,'targets',1);
    assertTrue(all(ds2.sa.targets==1));
    assertExceptionThrown(@()cosmo_meeg_dataset(ds,'targets',[1 2]),'');



function test_meeg_eeglab_txt_io()
    ds=cosmo_synthetic_dataset('type','meeg');

    tmp_fn=sprintf('_tmp_%06.0f.txt',rand()*1e5);
    file_remover=onCleanup(@()delete(tmp_fn));
    fid=fopen(tmp_fn,'w');
    file_closer=onCleanup(@()fclose(fid));

    chans=[{' '} ds.a.fdim.values{1}];
    fprintf(fid,'%s\t',chans{:});
    fprintf(fid,'\n');

    times=ds.a.fdim.values{2};
    ntime=numel(times);
    nsamples=size(ds.samples,1);

    for k=1:nsamples
        for j=1:ntime
            data=ds.samples(k,ds.fa.time==j);
            fprintf(fid,'%.3f',times(j));
            fprintf(fid,'\t%.4f',data);
            fprintf(fid,'\n');
        end
    end

    fclose(fid);
    ds2=cosmo_meeg_dataset(tmp_fn);

    assertElementsAlmostEqual(ds.samples,ds2.samples,'absolute',1e-4);
    assertEqual(ds.a.fdim.values{1},ds2.a.fdim.values{1});
    assertElementsAlmostEqual(ds.a.fdim.values{2},...
                                    1000*ds2.a.fdim.values{2});
    assertEqual(ds.a.fdim.labels,ds2.a.fdim.labels);
    assertEqual(ds.fa,ds2.fa);

    % test trials option
    nsamples=size(ds.samples,1);
    trial_idx=ceil(rand(1,2)*nsamples);
    ds_trials=cosmo_meeg_dataset(tmp_fn,'trials',trial_idx);
    ds_expected_trials=cosmo_slice(ds,trial_idx);
    assertElementsAlmostEqual(ds_trials.samples,...
                                ds_expected_trials.samples,...
                                'absolute',1e-4);

    % test illegal options
    aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_meeg_dataset(varargin{:}),'');
    illegal_args={nsamples+1,0,struct,{},'foo',true,1.5};
    for j=1:numel(illegal_args)
        arg=illegal_args{j};
        aet(tmp_fn,'trials',arg);
        aet(tmp_fn,cosmo_structjoin('trials',arg));
    end

    % add bogus data, expect exception
    fid=fopen(tmp_fn,'a');
    fprintf(fid,'.3');
    fclose(fid);
    file_closer=[];

    aet(tmp_fn);

    tmp2_fn=sprintf('_tmp_%06.0f.txt',rand()*1e5);
    file_remover2=onCleanup(@()delete(tmp2_fn));
    cosmo_map2meeg(ds2,tmp2_fn);
    ds3=cosmo_meeg_dataset(tmp2_fn);
    assertEqual(ds2,ds3);


function test_meeg_ft_io()
    ds=cosmo_synthetic_dataset('type','meeg');
    tmp_fn=sprintf('_tmp_%06.0f.mat',rand()*1e5);
    file_remover=onCleanup(@()delete(tmp_fn));

    cosmo_map2meeg(ds,tmp_fn);
    ds2=cosmo_meeg_dataset(tmp_fn);
    assertEqual(ds.a.meeg.samples_field,ds2.a.meeg.samples_field);
    ds.a.meeg=[];
    ds.sa=struct();
    ds2.a.meeg=[];

    % deal with rounding errors in Octave
    assertElementsAlmostEqual(ds.samples,ds2.samples);
    assertElementsAlmostEqual(ds.a.fdim.values{2},ds2.a.fdim.values{2});

    ds3=cosmo_meeg_dataset(ds2);
    assertEqual(ds2,ds3);

    ds2.samples=ds.samples;
    ds2.a.fdim.values{2}=ds.a.fdim.values{2};
    assertEqual(ds,ds2);



function test_meeg_ft_io_exceptions()
    aeti=@(varargin)assertExceptionThrown(@()...
                    cosmo_meeg_dataset(varargin{:}),'');
    aeto=@(varargin)assertExceptionThrown(@()...
                    cosmo_map2meeg(varargin{:}),'');
    ds=cosmo_synthetic_dataset('type','timefreq');
    aeti('file_without_extension');
    aeti('file.with_unknown_extension');

    aeto(ds,'file_without_extension');
    aeto(ds,'file.with_unknown_extension');

    aeto(ds,'eeglab_timelock.txt'); % not supported


function dimords=get_ft_dimords()
    dimords={   'chan_time',...
                'rpt_chan_time'...
                'subj_chan_time'...
                'chan_freq',...
                'rpt_chan_freq',...
                'subj_chan_freq',...
                'chan_freq_time',...
                'rpt_chan_freq_time',...
                'subj_chan_freq_time',...
                };

function [ft,fdim,data_label]=generate_ft_struct(dimord)
    seed=1;

    fdim=struct();
    fdim.values=cell(3,1);
    fdim.labels=cell(3,1);

    ft=struct();
    ft.dimord=dimord;

    dims=cosmo_strsplit(dimord,'_');
    ndim=numel(dims);
    sizes=[3 4 5 6];

    chan_values={'MEG0113' 'MEG0112' 'MEG0111' 'MEG0122'...
                    'MEG0123' 'MEG0121' 'MEG0132'};
    freq_values=(2:2:24);
    time_values=(-1:.1:2);

    data_label='avg';
    ntrials=1;
    nkeep=0;

    for k=1:ndim
        idxs=1:sizes(k);
        switch dims{k}
            case 'rpt'
                data_label='trial';
                ntrials=numel(idxs);

            case 'subj'
                data_label='individual';
                ntrials=numel(idxs);

            case 'chan'
                ft.label=chan_values(idxs);
                nkeep=nkeep+1;
                fdim.values{nkeep}=ft.label;
                fdim.labels{nkeep}='chan';

            case 'freq'
                ft.freq=freq_values(idxs);
                data_label='powspctrm';
                nkeep=nkeep+1;
                fdim.values{nkeep}=ft.freq;
                fdim.labels{nkeep}='freq';

            case 'time'
                ft.time=time_values(idxs);
                nkeep=nkeep+1;
                fdim.values{nkeep}=ft.time;
                fdim.labels{nkeep}='time';

        end
    end

    fdim.values=fdim.values(1:nkeep);
    fdim.labels=fdim.labels(1:nkeep);

    keep_sizes=sizes(1:k);
    ft.(data_label)=cosmo_norminv(cosmo_rand(keep_sizes,'seed',seed));
    ft.cfg=struct();
    ft.trialinfo=[(1:ntrials);(ntrials:-1:1)]';

    if strcmp(data_label,'trial')
        ft.avg=mean(ft.(data_label),1);
    end


function test_eeglab_io()
    datatypes={'timef','erp','itc'};

    args=cosmo_cartprod({{true,false},...
                         {true,false},...
                         datatypes});


    ncombi=size(args,1);
    for k=1:ncombi
        arg=args(k,:);
        [s,ds,ext]=build_eeglab_dataset_struct(arg{:});

        ds_from_struct=cosmo_meeg_dataset(s);
        assertEqual(ds.samples,ds_from_struct.samples);
        assertEqual(ds,ds_from_struct);

        % store, then read using cosmo_meeg_dataset
        fn=sprintf('%s.%s',tempname(),ext);
        save(fn,'-mat','-struct','s');
        cleaner=onCleanup(@()delete(fn));

        ds_loaded=cosmo_meeg_dataset(fn);
        assertEqual(ds,ds_loaded);
        clear cleaner;

        s_converted=cosmo_map2meeg(ds,['-' ext]);
        assertEqual(s,s_converted)

        % store using cosmo_map2meeg, then read
        cosmo_map2meeg(ds,fn);
        cleaner=onCleanup(@()delete(fn));

        s_loaded=load(fn,'-mat');
        assertEqual(s_loaded,s);
        assertEqual(s,s_loaded);
        clear cleaner;
    end

function test_eeglab_io_trials()
% test with loading a subset of trials
    datatypes={'timef','erp','itc'};

    args=cosmo_cartprod({{true,false},...
                         {true,false},...
                         datatypes});

    ncombi=size(args,1);
    for k=1:ncombi
        arg=args(k,:);
        [s,ds,ext]=build_eeglab_dataset_struct(arg{:});

        nsamples=size(ds.samples,1);
        trial_idx=ceil(rand(1,2)*nsamples);
        ds_expected_trials=cosmo_slice(ds,trial_idx);

        % with struct input
        ds_trials=cosmo_meeg_dataset(s,'trials',trial_idx);
        assertElementsAlmostEqual(ds_trials.samples,...
                                ds_expected_trials.samples,...
                                'absolute',1e-4);

        % store, then read using cosmo_meeg_dataset
        fn=sprintf('%s.%s',tempname(),ext);
        save(fn,'-mat','-struct','s');
        cleaner=onCleanup(@()delete(fn));

        ds_loaded=cosmo_meeg_dataset(fn,'trials',trial_idx);
        assertEqual(ds_loaded,ds_expected_trials);


        % test illegal options
        aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_meeg_dataset(varargin{:}),'');
        illegal_args={nsamples+1,0,struct,{},'foo',true,1.5};
        for j=1:numel(illegal_args)
            arg=illegal_args{j};
            aet(s,'trials',arg);
        end

        clear cleaner;
    end

function test_eeglab_io_ersp()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_meeg_dataset(varargin{:}),'');

    args=cosmo_cartprod({{true,false},...
                         {false},...
                         {'ersp'},...
                         {false,true}});

     ncombi=size(args,1);
    for k=1:ncombi
        arg=args(k,1:3);
        [s,ds_cell,ext]=build_eeglab_dataset_struct(arg{:});

        % either load baseline data or original data
        with_baseline=args{k,4};
        if with_baseline
            load_args={'data_field','erspbase'};
            ds=ds_cell{2};
        else
            load_args={'data_field','ersp'};
            ds=ds_cell{1};
        end

        % illegal without arguments or wrong arguments
        aet(s);
        aet(s,'data_field','foo');
        aet(s,'data_field',false);

        % load data with correct arguments
        ds_loaded=cosmo_meeg_dataset(s,load_args{:});
        assertEqual(ds_loaded,ds);


         % store, then read using cosmo_meeg_dataset
        fn=sprintf('%s.%s',tempname(),ext);
        save(fn,'-mat','-struct','s');
        cleaner=onCleanup(@()delete(fn));

        ds_loaded=cosmo_meeg_dataset(fn,load_args);

        % writing the file is not supported
        assertExceptionThrown(@()cosmo_map2meeg(ds,fn),'');

        clear cleaner

        assertEqual(ds_loaded,ds);
    end







function test_eeglab_io_exceptions()
    aet_md=@(varargin)assertExceptionThrown(@()...
                            cosmo_meeg_dataset(varargin{:}),'');
    aet_m2m=@(varargin)assertExceptionThrown(@()...
                            cosmo_map2meeg(varargin{:}),'');

    s=build_eeglab_dataset_struct(true,true,'timef');

    % bad datatype
    s.datatype='foo';
    aet_md(s)

    % output is not a filename
    ds=cosmo_synthetic_dataset('type','timefreq');
    aet_m2m(ds,struct);

    % bad  fdim
    good_labels={'chan','freq','time'};
    all_bad_labels={'chan','freq','time','foo'};

    for dim=1:numel(good_labels)
        for j=1:numel(all_bad_labels)
            ds_bad_chan_fdim=ds;
            bad=all_bad_labels{j};
            if ~strcmp(bad, good_labels{dim})
                ds_bad_chan_fdim.a.fdim.labels{dim}=bad;
                aet_m2m(ds_bad_chan_fdim,'-dattimef');
            end
        end
    end


function [s,ds,ext]=build_eeglab_dataset_struct(has_ica,has_trial,datatype,...
                        chan_dim,freq_dim,time_dim)
    if nargin<6
        time_dim=randint();
    end

    if nargin<5
        freq_dim=randint();
    end

    if nargin<4
        chan_dim=randint();
    end


    % trial dimension
    if has_trial
        trial_dim=randint();
    else
        trial_dim=1;
    end

    if strcmp(datatype,'ersp')
        % has baseline corrected data together with baseline data
        builder=@build_eeglab_dataset_struct;
        args={chan_dim,freq_dim,time_dim};
        [s1,ds1,ext]=builder(has_ica,has_trial,...
                                'ersp_baselinecorrected',args{:});
        [s2,ds2]=builder(has_ica,has_trial,...
                                'erspbase',args{:});

        keys=fieldnames(s1);
        for k=1:numel(keys)
            key=keys{k};
            s2.(key)=s1.(key);
        end

        s=s2;
        s.datatype=upper(datatype);

        % make sure parameters are the same
        ds1.a.meeg.parameters=s.parameters;
        ds2.a.meeg.parameters=s.parameters;

        if isfield(s,'chanlabels')
            chan_labels=s.chanlabels;
            ds1.a.fdim.values{1}=chan_labels;
            ds2.a.fdim.values{1}=chan_labels;
        end

        ds={ds1,ds2};
        % remove second part from extension
        ext=regexprep(ext,'_.*','');
        return;
    end

    % channel / component dimension
    if has_ica
        chan_prefix='comp';
        ext_prefix='ica';

        make_chan_prefix_func=@()chan_prefix;
    else
        chan_prefix='chan';
        ext_prefix='dat';

        make_chan_prefix_func=@randstr;
    end

    has_freq=2;

    switch datatype
        case 'timef'
            chan_suffix='_timef';

        case 'erp'
            chan_suffix='';

        case 'ersp_baselinecorrected'
            chan_suffix='_ersp';

        case 'erspbase'
            chan_suffix='_erspbase';

        case 'itc';
            chan_suffix='_itc';

        otherwise
            assert(false);
    end

    make_chan_label=@(idx) sprintf('%s%d',make_chan_prefix_func(),idx);

    chan_label={chan_prefix};
    chan_value={arrayfun(make_chan_label,1:chan_dim,...
                            'UniformOutput',false)};

    % frequency dimension
    switch datatype
        case {'timef','ersp_baselinecorrected','itc','erspbase'}
            has_freq=true;


        case {'erp'};
            has_freq=false;

        otherwise
            assert(false);
    end

    if has_freq
        freq_label={'freq'};
        freq_value={(1:freq_dim)*2};
        samples_type='timefreq';
    else
        freq_dim=[];
        freq_label={};
        freq_value={};
        samples_type='timelock';
    end

    ext_suffix=datatype;

    hastime=~strcmp(datatype,'erspbase');

    if hastime
        % include time dimension
        time_label={'time'};
        time_value={(1:time_dim())*.2-.1};
    else
        % no time dimension
        time_dim=[];
        time_label={};
        time_value={};
    end

    % data
    dim_sizes=[trial_dim,chan_dim,freq_dim,time_dim];
    dim_sizes_without_chan=[dim_sizes([1, 3:end]), 1];
    data_arr=randn(dim_sizes);

    % params
    parameters={randstr(), randstr()};

    % make dataset
    ds=cosmo_flatten(data_arr,...
                        [chan_label,freq_label,time_label],...
                        [chan_value,freq_value,time_value]);
    ds.sa=struct();
    ds.a.meeg.samples_field='trial';
    ds.a.meeg.samples_type=samples_type;
    ds.a.meeg.samples_label='rpt';
    ds.a.meeg.parameters=parameters;


    s=struct();
    for k=1:chan_dim
        key=sprintf('%s%d%s',chan_prefix,k,chan_suffix);
        value=data_arr(:,k,:);
        value_rs=reshape(value,dim_sizes_without_chan);

        if has_freq
            % it seems that for freq data, single trial data is the last
            % dimension, whereas for erp data, single trial data is the first
            % dimension.
            value_rs=shiftdim(value_rs,1);
        end

        s.(key)=value_rs;
    end

    if ~has_ica
        s.chanlabels=chan_value{1};
        assert(iscellstr(s.chanlabels));
    end

    if has_freq
        s.freqs=freq_value{1};
    end

    if hastime
        s.times=time_value{1};
    end

    s.datatype=upper(ext_suffix);
    s.parameters=parameters;

    ext=[ext_prefix, ext_suffix];


function test_dimord_label()
    opt=struct();
    opt.samples_label={'','rpt','trial'};
    opt.nsamples={1,randint(),10};
    opt.datatype={'timefreq','timelock'};

    combis=cosmo_cartprod(opt);
    n_combi=numel(combis);

    for k=1:n_combi
        c=combis{k};

        ds=cosmo_synthetic_dataset('type',c.datatype,...
                                        'ntargets',1,...
                                        'nchunks',c.nsamples,...
                                    'size','big');
        assertEqual(size(ds.samples,1),c.nsamples);

        with_samples_label=~isempty(c.samples_label);
        if with_samples_label
            ds.a.meeg.samples_label=c.samples_label;
        else
            ds.a.meeg=rmfield(ds.a.meeg,'samples_label');
        end

        data_is_average=c.nsamples==1 && ~with_samples_label;

        switch c.datatype
            case 'timefreq'
                samples_field='powspctrm';

            case 'timelock'
                if data_is_average
                    samples_field='avg';
                else
                    samples_field='trial';
                end

            otherwise
                assert(false)
        end


        ft=cosmo_map2meeg(ds);

        labels=cosmo_strsplit(ft.dimord,'_');

        ndim_expected=numel(ds.a.fdim.labels);
        if ~data_is_average
            ndim_expected=ndim_expected+1;
        end

        assertEqual(numel(labels),ndim_expected);
        assertEqual(numel(size(ft.(samples_field))),ndim_expected);

    end


function test_meeg_source_dataset_pos_dim_inside_fields()
% mapping back and forth should be fine whether or not the
% 'pos', 'dim' and 'inside' fields are there or not
    ds_orig=cosmo_synthetic_dataset('type','source','size','huge');
    ft_orig=cosmo_map2meeg(ds_orig);

    for has_dim=[false,true]
        for has_tri=[false,true]
            for has_inside=[false,true]
                ft=ft_orig;

                if has_dim
                    ft.dim=[2 2 2];
                end

                n_pos=size(ft.pos,1);

                if has_tri
                    ft.tri=ceil(rand(5,3)*max(n_pos));
                end

                if ~has_inside
                    ft=rmfield(ft,'inside');
                end

                func=@()cosmo_meeg_dataset(ft);

                % verify fields are there
                ds=func();
                assertEqual(has_dim,isfield(ds.a.meeg,'dim'));
                assertEqual(has_tri,isfield(ds.a.meeg,'tri'));

                % map back
                ft_back=cosmo_map2meeg(ds);

                % cosmo_map2meeg always returns an inside field, so for
                % now we remove it if it is present here
                if ~has_inside
                    ft_back=rmfield(ft_back,'inside');
                end

                % ensure expected fields are preserved
                assertEqual(ft,ft_back);
            end
        end
    end


function x=randint()
    x=ceil(rand()*10+5);

function x=randstr()
    x=char(rand(1,10)*24+65);
