function test_suite = test_meeg_baseline_correct
% tests for cosmo_meeg_baseline_correct
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_meeg_baseline_correct_ft_comparison()
    if cosmo_skip_test_if_no_external('fieldtrip')
        return;
    end

    if cosmo_wtf('is_octave')
        cosmo_notify_test_skipped(['ft_freqbaseline is not compatible '...
                                        'with Octave']);
    end

    interval=[-.15 -.04];
    [ds,ds_ref]=get_test_dataset(interval);

    methods={'relative','absolute','relchange'};

    ft=cosmo_map2meeg(ds);

    for k=1:numel(methods)
        method=methods{k};
        opt=struct();
        opt.baseline=interval;
        opt.baselinetype=method;


        % (unsupported in octave)
        ft_bl=ft_freqbaseline(opt,ft);

        ds_ft_bl=cosmo_meeg_dataset(ft_bl);

        if cosmo_isfield(ds_ft_bl','a.hdr_ft.cfg')
            ds_ft_bl.a.hdr_ft=rmfield(ds_ft_bl.a.hdr_ft,'cfg');
        end

        ds_ft_msk=ds_ft_bl.fa.chan==3 & ds_ft_bl.fa.freq==2;
        d_ft=cosmo_slice(ds_ft_bl,ds_ft_msk,2);
        if isfield(d_ft.a.meeg,'senstype')
            d_ft.a.meeg=rmfield(d_ft.a.meeg,'senstype');
        end

        ds_bl=cosmo_meeg_baseline_correct(ds,ds_ref,method);
        ds_bl_msk=ds_bl.fa.chan==3 & ds_bl.fa.freq==2;
        d=cosmo_slice(ds_bl,ds_bl_msk,2);

        assertElementsAlmostEqual(d_ft.samples,d.samples);
        assertEqual(d_ft.fa,d.fa);
        assertEqual(d_ft.a.fdim,d.a.fdim);
    end

function test_meeg_baseline_correct_regression()
    interval=[-.15 -.04];
    expected_samples={[ 2.7634  -2.6366   2.3689 -0.36892 -0.43043;...
                        -0.49007  -1.0933  0.79082   1.2092   0.1044 ],...
                      [ -0.63503   1.3096 -0.49296  0.49296  0.51511;...
                        -2.5308  -3.5553 -0.35529  0.35529  -1.5211 ],...
                      [ 1.7634  -3.6366   1.3689  -1.3689  -1.4304
                        -1.4901  -2.0933 -0.20918  0.20918  -0.8956 ]};
    [ds,ds_ref]=get_test_dataset(interval);

    methods={'relative','absolute','relchange'};

    ds_feature_msk=ds.fa.chan==3 & ds.fa.freq==2;

    for k=1:numel(methods)
        method=methods{k};

        for j=1:2
            if j==1
                ref=interval;
            else
                ref=ds_ref;
            end

            ds_bl=cosmo_meeg_baseline_correct(ds,ref,method);
            ds_bl_msk=ds_bl.fa.chan==3 & ds_bl.fa.freq==2;
            d=cosmo_slice(ds_bl,ds_bl_msk,2);

            assertElementsAlmostEqual(d.samples,expected_samples{k},...
                                                'absolute',1e-4);
            d_fa=cosmo_slice(ds.fa,ds_feature_msk,2,'struct');
            assertEqual(d.fa,d_fa);
        end
    end


function [ds,ds_ref]=get_test_dataset(interval)
    ds=cosmo_synthetic_dataset('type','timefreq','size','big',...
                                    'senstype','neuromag306_planar',...
                                    'nchunks',1);
    ds.sa=struct();
    ds.sa.rpt=(1:size(ds.samples,1))';
    msk=ds.fa.chan<=4 & ds.fa.freq<=2;
    ds=cosmo_slice(ds,msk,2);
    ds=cosmo_dim_prune(ds);

    matcher=@(x) interval(1) <= x & x <= interval(2);
    ds_ref=cosmo_slice(ds,cosmo_dim_match(ds,'time',matcher),2);
    ds_ref=cosmo_dim_prune(ds_ref);


function test_meeg_baseline_correct_illegal_inputs
    bc=@cosmo_meeg_baseline_correct;
    aet=@assertExceptionThrown;
    ds=cosmo_synthetic_dataset('type','timefreq','size','tiny');

    if cosmo_wtf('is_matlab')
        id_missing_arg='MATLAB:minrhs';
    else
        id_missing_arg='Octave:undefined-function';
    end

    aet(@()bc(ds,ds),id_missing_arg);
    aet(@()bc(ds,ds,'foo'),'');

    aet(@()bc(ds,cosmo_slice(ds,1),'relative'),'');
    aet(@()bc(ds,cosmo_slice(ds,1,2),'relative'),'');

    % test slicing
    bc(ds,cosmo_slice(ds,[1 2 3 4 5 6],1),'relative');
    aet(@()bc(ds,cosmo_slice(ds,[1 2 4 6 4 3],1),'relative'),'');



