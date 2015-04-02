
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

        ft_first_sample_all=ft.(key).(sub_key);
        ft_first_sample=ft_first_sample_all(ft.inside,:);
        assertEqual(ds.samples(1,:),ft_first_sample(:)');


        [ft_arr, ft_labels, ft_values]=cosmo_unflatten(ds,2,...
                                            'matrix_labels','pos');


        assertEqual(ft_arr(ft_arr~=0),ds.samples(:));
        assertEqual(ft_labels, fdim.labels);
        assertEqual(ft_values, fdim.values);

        % select single element, and ensure it is the same in the
        % fieldtrip struct as in the dataset struct
        dim_sizes=cellfun(@(x)size(x,2),fdim.values);
        ndim=numel(dim_sizes);
        rp=ceil(rand(1,ndim).*dim_sizes(:)');

        [nsamples,nfeatures]=size(ds.samples);
        ds_msk=false(1,nfeatures);
        ft_idx=cell(1,1+ndim);
        ft_idx{1}=randperm(nsamples);
        for k=1:ndim
            dim_label=fdim.labels{k};
            ds_msk = ds_msk | rp(k)~=ds.fa.(dim_label);

            ft_values=ft.(dim_label);
            switch dim_label
                case 'pos'
                    ft_idx{k+1}=find(all(bsxfun(@eq,...
                                    ft_values(rp(k),:),ft_values),2));

                otherwise
                    ft_idx{k+1}=find(ft_values(rp(k))==ft_values);
            end
        end

        ds_sel=cosmo_slice(cosmo_slice(ds,~ds_msk,2),ft_idx{1});
        ft_sel=ft_arr(ft_idx{:});

        if isempty(ft_sel)
            assertEqual(ds.samples,0);
        else
            assertEqual(ds_sel.samples,ft_sel);
        end



        %re-order features
        nfeatures=size(ds.samples,2);
        ds=cosmo_slice(ds,randperm(nfeatures),2);

        ft2=cosmo_map2meeg(ds);
        assertEqual(ft,ft2);


    end


function test_meeg_fmri_dataset()
    ds=cosmo_synthetic_dataset('type','source');
    ds_fmri=cosmo_fmri_dataset(ds);
    ft=cosmo_map2meeg(ds);
    ds_ft_fmri=cosmo_fmri_dataset(ft);

    ds_vol=cosmo_vol_grid_convert(ds,'tovol');
    assertEqual(ds_vol,ds_fmri);

    assertTrue(isempty(fieldnames(ds_ft_fmri.sa)))
    ds_vol=rmfield(ds_vol,'sa');
    ds_ft_fmri=rmfield(ds_ft_fmri,'sa');
    assertEqual(ds_vol,ds_ft_fmri);



function [ft,fdim,data_label]=generate_ft_source(tp)
    ft=struct();
    dim_pos_range={-3:3,-4:4,-5:5};
    nsamples=2;
    freq=[3 5 7 9];
    time=[-1 0 1 2];

    ft.dim=cellfun(@numel,dim_pos_range);
    ft.pos=cosmo_cartprod(dim_pos_range);
    ft.inside=sum(ft.pos.^2,2)<40;

    fdim=struct();

    switch tp
        case 'freq'
            ft.freq=freq;
            %ft.cumtapcnt=(1:nsamples)';
            ft.method='average';
            ft.avg.pow=generate_data(ft.inside,numel(freq));
            fdim.labels={'pos';'freq'};
            fdim.values={ft.pos';freq(:)'};
            data_label={'avg','pow'};

        case 'time'
            ft.time=time;
            ft.method='average';
            ft.avg.pow=generate_data(ft.inside,numel(time));
            fdim.labels={'pos';'time'};
            fdim.values={ft.pos';time(:)'};
            data_label={'avg','pow'};

        case 'rpt_trial';
            ft.time=time;
            ft.method='rawtrial';
            ft.trial=generate_data(ft.inside,numel(time),nsamples);
            fdim.labels={'pos';'time'};
            fdim.values={ft.pos';time(:)'};
            data_label={'trial','pow'};


    end


function d=generate_data(inside,dim_size,struct_length)
    as_struct=nargin>=3;

    if ~as_struct
        struct_length=1;
    end

    dim_other=[dim_size struct_length];
    nsensors=numel(inside);
    nother=prod(dim_other);
    d_mat=NaN(nsensors, nother);
    d_mat(inside,:)=cosmo_rand([sum(inside) nother],'seed',1);
    d=reshape(d_mat,[nsensors dim_other]);

    if as_struct
        c=cell(struct_length,1);
        for k=1:struct_length
            c{k}.pow=d(:,:,k);
        end
        d=cat(2,c{:});

    end
