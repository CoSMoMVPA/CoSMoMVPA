
function test_suite=test_meeg_source()
    initTestSuite;

function test_meeg_dataset()
    tps={'freq','time','rpt_trial'};
    for j=1:numel(tps)
        [ft,fdim,data_label]=generate_ft_source(tps{j});
        ds=cosmo_meeg_dataset(ft);
    end




function [ft,fdim,data_label]=generate_ft_source(tp)
    ft=struct();
    dim_pos={-3:3,-4:4,-5:5};
    nsamples=5;
    freq=3;
    time=-2:.1:1;

    ft.dim=cellfun(@numel,dim_pos);
    ft.pos=cosmo_cartprod(dim_pos);
    ft.inside=sum(ft.pos.^2,2)<40;

    nfeatures=numel(ft.inside);

    fdim=struct();

    switch tp
        case 'freq'
            ft.freq=freq;
            ft.cumtapcnt=(1:nsamples)';
            ft.method='average';
            ft.avg.pow=generate_data([1 nfeatures]);
            fdim.labels={'freq'};
            fdim.values={freq(:)};
            data_label={'avg','pow'};

        case 'time'
            ft.time=time;
            ft.method='average';
            ft.avg.pow=generate_data([1 nfeatures]);
            fdim.labels={'time'};
            fdim.values={time(:)};
            data_label={'avg','pow'};

        case 'rpt_trial';
            ft.time=time;
            ft.method='rawtrial';
            ft.trial=generate_data([1 nfeatures],nsamples);
            fdim.labels={'time'};
            fdim.values={time(:)};
            data_label={'trial','pow'};

    end


function d=generate_data(sz,struct_length)
    as_struct=nargin>=2;

    if ~as_struct
        struct_length=1;
    end


    d=cosmo_rand([sz struct_length],'seed',1);

    if as_struct
        c=cell(struct_length,1);
        for k=1:struct_length
            c{k}.pow=d(:,:,k);
        end
        d=cat(2,c{:});

    end
