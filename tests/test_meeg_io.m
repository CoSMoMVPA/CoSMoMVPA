function test_suite=test_meeg_io()
% tests for MEEG input/output
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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

    % add bogus datamox
    fid=fopen(tmp_fn,'a');
    fprintf(fid,'.3');
    fclose(fid);
    file_closer=[];

    assertExceptionThrown(@()cosmo_meeg_dataset(tmp_fn),'');

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

    aeto(ds,'eeglab_timelock.txt');


function dimords=get_ft_dimords()
    dimords={   'chan_time',...
                'rpt_chan_time'...
                'chan_freq',...
                'rpt_chan_freq',...
                'chan_freq_time',...
                'rpt_chan_freq_time',...
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
    ft.(data_label)=norminv(cosmo_rand(keep_sizes,'seed',seed));
    ft.cfg=struct();
    ft.trialinfo=[(1:ntrials);(ntrials:-1:1)]';

    if strcmp(data_label,'trial')
        ft.avg=mean(ft.(data_label),1);
    end


function test_eeglab_io()
    args=cosmo_cartprod(repmat({{true;false}},1,3));
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

function test_eeglab_io_exceptions()
    aet_md=@(varargin)assertExceptionThrown(@()...
                            cosmo_meeg_dataset(varargin{:}),'');
    aet_m2m=@(varargin)assertExceptionThrown(@()...
                            cosmo_map2meeg(varargin{:}),'');

    s=build_eeglab_dataset_struct(true,true,true);

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




function [s,ds,ext]=build_eeglab_dataset_struct(has_ica,has_freq,has_trial)
    % trial dimension
    if has_trial
        trial_dim=randint();
    else
        trial_dim=1;
    end


    % channel / component dimension
    chan_dim=randint();
    if has_ica
        chan_prefix='comp';
        ext_prefix='ica';

        make_chan_prefix_func=@()chan_prefix;
    else
        chan_prefix='chan';
        ext_prefix='dat';

        make_chan_prefix_func=@randstr;
    end

    if has_freq
        chan_suffix='_timef';
    else
        chan_suffix='';
    end

    make_chan_label=@(idx) sprintf('%s%d',make_chan_prefix_func(),idx);

    chan_label={chan_prefix};
    chan_value={arrayfun(make_chan_label,1:chan_dim,...
                            'UniformOutput',false)};

    % frequency dimension
    if has_freq
        freq_dim=randint();
        freq_label={'freq'};
        freq_value={(1:freq_dim)*2};
        samples_type='timefreq';
        ext_suffix='timef';
    else
        freq_dim=[];
        freq_label={};
        freq_value={};
        samples_type='timelock';
        ext_suffix='erp';
    end

    % time dimensions
    time_dim=randint();
    time_label={'time'};
    time_value={(1:time_dim())*.2-.1};

    % data
    dim_sizes=[trial_dim,chan_dim,freq_dim,time_dim];
    dim_sizes_without_chan=dim_sizes([1, 3:end]);
    data_arr=randn(dim_sizes);

    % params
    parameters={randstr(), randstr()};

    % datafiles
    % (use sorted order for datafiles so that testing for presence of
    % correct datafiles is easier)
    datafile_count=ceil(trial_dim/3);
    datafiles=sort(arrayfun(@(x)randstr(),ones(1,datafile_count),...
                            'UniformOutput',false));
    datafile_idxs=ceil(rand(1,trial_dim)*datafile_count);

    % ensure none empty
    datafile_idxs(1:datafile_count)=randperm(datafile_count);

    sa_datafiles=cell(trial_dim,1);
    datatrials=cell(1,datafile_count);
    for k=1:datafile_count
        msk=datafile_idxs==k;
        datatrials{k}=find(msk);
        sa_datafiles(msk)=repmat(datafiles(k),sum(msk),1);
    end

    ds=cosmo_flatten(data_arr,...
                        [chan_label,freq_label,time_label],...
                        [chan_value,freq_value,time_value]);

    ds.a.meeg.samples_field='trial';
    ds.a.meeg.samples_type=samples_type;
    ds.a.meeg.samples_label='rpt';
    ds.a.meeg.parameters=parameters;
    ds.sa.datafiles=sa_datafiles;


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
    s.times=time_value{1};
    s.datatype=upper(ext_suffix);
    s.datafiles=datafiles;
    s.datatrials=datatrials;
    s.parameters=parameters;

    ext=[ext_prefix, ext_suffix];


function x=randint()
    x=ceil(rand()*10+5);

function x=randstr()
    x=char(rand(1,10)*24+65);



