
function test_suite=test_meeg_source()
    initTestSuite;

function test_meeg_dataset()
    tps={'freq','time','rpt_trial'};
    for j=1:numel(tps)
        [ft,fdim,data_label]=generate_ft_source(tps{j});
        ds=cosmo_meeg_dataset(ft);

        % check fdim
        assertEqual(ds.a.fdim,fdim);

        key=data_label{1};
        sub_key=data_label{2};

        % check samples
        ft_samples=cat(1,ft.(key).(sub_key));
        assertEqual(ds.samples,ft_samples);
        labels=fdim.labels;

        nfeatures=size(ds.samples,2);

        for k=1:numel(labels)
            label=labels{k};
            switch label
                case 'pos'
                    fa_values=1:nfeatures;
                otherwise
                    fa_values=ones(1,nfeatures);
            end

            assertEqual(ds.fa.(label),fa_values);
        end

        [unused,i]=cosmo_dim_find(ds,'pos');
        ds_pos=ds.a.fdim.values{i}(:,ds.fa.pos);

        assertEqual(ds_pos,ft.pos');

        nfeatures=size(ds.samples,2);
        ds=cosmo_slice(ds,randperm(nfeatures),2);

        ft2=cosmo_map2meeg(ds);

        mp=cosmo_align({ft2.pos(:,1), ft2.pos(:,2), ft2.pos(:,3)},...
                    {ft.pos(:,1), ft.pos(:,2), ft.pos(:,3)});

        assertEqual(ft.pos,ft2.pos(mp,:));
        assertEqual(ft.inside,ft2.inside(mp,:));

        ft2_samples=cat(1,ft2.(key).(sub_key));

        assertEqual(ft_samples,ft2_samples(:,mp));

    end




function [ft,fdim,data_label]=generate_ft_source(tp)
    ft=struct();
    dim_pos={-3:3,-4:4,-5:5};
    nsamples=5;
    freq=3;
    time=-2;

    ft.dim=cellfun(@numel,dim_pos);
    ft.pos=cosmo_cartprod(dim_pos);
    ft.inside=sum(ft.pos.^2,2)<40;

    nfeatures=numel(ft.inside);

    fdim=struct();

    switch tp
        case 'freq'
            ft.freq=freq;
            %ft.cumtapcnt=(1:nsamples)';
            ft.method='average';
            ft.avg.pow=generate_data([1 nfeatures]);
            fdim.labels={'freq';'pos'};
            fdim.values={freq(:);ft.pos'};
            data_label={'avg','pow'};

        case 'time'
            ft.time=time;
            ft.method='average';
            ft.avg.pow=generate_data([1 nfeatures]);
            fdim.labels={'time';'pos'};
            fdim.values={time(:);ft.pos'};
            data_label={'avg','pow'};

        case 'rpt_trial';
            ft.time=time;
            ft.method='rawtrial';
            ft.trial=generate_data([1 nfeatures],nsamples);
            fdim.labels={'time';'pos'};
            fdim.values={time(:);ft.pos'};
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
