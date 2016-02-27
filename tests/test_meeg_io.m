function test_suite=test_meeg_io()
% tests for MEEG input/output
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_meeg_dataset()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_meeg_dataset(varargin{:}),'');

    dimords=get_dimords();
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


function test_meeg_eeglab_io()
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





function dimords=get_dimords()
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


