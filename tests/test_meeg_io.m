function test_suite=test_meeg_io()
    initTestSuite;


function test_meeg_dataset()
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
            assertEqual(data_size(2:end),fdim_sizes);
        else
            assertEqual(data_size,fdim_sizes);
        end

        assertAlmostEqual(data(:),ds.samples(:));

        ds2=cosmo_slice(ds,randperm(nfeatures),2);
        ft2=cosmo_map2meeg(ds2);

        if isfield(ft,'cfg')
            ft=rmfield(ft,'cfg');
        end

        assertEqual(ft,ft2);
    end

    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_meeg_dataset(varargin{:}),'');
    aet(struct());
    aet(struct('avg',1));
    aet(struct('avg',1,'dimord','rpt_foo'));


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
    fdim.values=cell(0);
    fdim.labels=cell(0);

    ft=struct();
    ft.dimord=dimord;

    dims=cosmo_strsplit(dimord,'_');
    ndim=numel(dims);
    sizes=[3 4 5 6];

    chan_values={'MEG0113' 'MEG0112' 'MEG0111' 'MEG0122'...
                    'MEG0123' 'MEG0121' 'MEG0132'}';
    freq_values=(2:2:24);
    time_values=(-1:.1:2);

    data_label='avg';
    ntrials=1;

    for k=1:ndim
        idxs=1:sizes(k);
        switch dims{k}
            case 'rpt'
                data_label='trial';
                ntrials=numel(idxs);

            case 'chan'
                ft.label=chan_values(idxs);
                fdim.values{end+1}=ft.label;
                fdim.labels{end+1}='chan';

            case 'freq'
                ft.freq=freq_values(idxs);
                data_label='powspctrm';
                fdim.values{end+1}=ft.freq';
                fdim.labels{end+1}='freq';

            case 'time'
                ft.time=time_values(idxs);
                fdim.values{end+1}=ft.time';
                fdim.labels{end+1}='time';
        end
    end

    keep_sizes=sizes(1:k);
    ft.(data_label)=norminv(cosmo_rand(keep_sizes,'seed',seed));
    ft.cfg=struct();
    ft.trialinfo=(1:ntrials)';


