function test_suite = test_meeg_baseline_correct
    initTestSuite;

function test_meeg_baseline_correct_ft_comparison()
    interval=[-.15 -.05];
    methods={'relative','absolute','relchange'};
    ds=cosmo_synthetic_dataset('type','timefreq','size','big',...
                                    'senstype','neuromag306_planar');
    ds.sa=struct();
    ds.sa.rpt=(1:size(ds.samples,1))';
    msk=ds.fa.chan<=4 & ds.fa.freq<=2;
    ds=cosmo_slice(ds,msk,2);
    ds=cosmo_dim_prune(ds);

    matcher=@(x) interval(1) <= x & x <= interval(2);
    ds_ref=cosmo_slice(ds,cosmo_dim_match(ds,'time',matcher),2);
    ds_ref=cosmo_dim_prune(ds_ref);

    ft=cosmo_map2meeg(ds);

    for k=1:numel(methods)
        method=methods{k};
        opt=struct();
        opt.baseline=interval;
        opt.baselinetype=method;
        ft_bl=ft_freqbaseline(opt,ft);

        ds_ft_bl=cosmo_meeg_dataset(ft_bl);
        nf=size(ds_ft_bl.samples);

        if cosmo_isfield(ds_ft_bl','a.hdr_ft.cfg')
            ds_ft_bl.a.hdr_ft=rmfield(ds_ft_bl.a.hdr_ft,'cfg');
        end

        ds_ft_msk=ds_ft_bl.fa.chan==3 & ds_ft_bl.fa.freq==2;
        d_ft=cosmo_slice(ds_ft_bl,ds_ft_msk,2);
        d_ft.a.meeg=rmfield(d_ft.a.meeg,'senstype');

        for j=1:2
            if j==1
                ref=interval;
            else
                ref=ds_ref;
            end

            ds_bl=cosmo_meeg_baseline_correct(ds,ref,method);
            ds_msk=ds_bl.fa.chan==3 & ds_bl.fa.freq==2;
            d=cosmo_slice(ds_bl,ds_msk,2);

            assertEqual(d,d_ft);
        end
    end

function test_meeg_baseline_correct_illegal_inputs
    bc=@cosmo_meeg_baseline_correct;
    aet=@assertExceptionThrown;
    ds=cosmo_synthetic_dataset('type','timefreq','size','tiny');

    aet(@()bc(ds,ds),'MATLAB:minrhs');
    aet(@()bc(ds,ds,'foo'),'');

    aet(@()bc(ds,cosmo_slice(ds,1),'relative'),'');
    aet(@()bc(ds,cosmo_slice(ds,1,2),'relative'),'');

    % test slicing
    bc(ds,cosmo_slice(ds,[1 2 3 4 5 6],1),'relative');
    aet(@()bc(ds,cosmo_slice(ds,[1 2 4 6 4 3],1),'relative'),'');



