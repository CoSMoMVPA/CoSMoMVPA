function test_suite = test_meeg_baseline_correct
% tests for cosmo_meeg_baseline_correct
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_meeg_baseline_correct_ft_comparison_methods()
    methods={'relative','absolute','relchange'};
    references={'manual','ft','ds'};

    combis=cosmo_cartprod({methods,references});
    ncombis=size(combis,1);

    for k=1:ncombis
        combi=combis(k,:);
        method=combi{1};
        reference=combi{2};

        % random interval
        start=rand(1)*-.25;
        dur=.05+rand(1)*.2;
        interval=start+[0 dur];

        helper_test_meeg_baseline_correct_comparison(interval,...
                                                        method,reference);
    end


function helper_test_meeg_baseline_correct_comparison(interval,method,...
                                                    reference)

    switch reference
        case 'ft'
            if cosmo_skip_test_if_no_external('fieldtrip')
                return;
            end

            if cosmo_wtf('is_octave')
                cosmo_notify_test_skipped(['ft_freqbaseline is not '...
                                                'compatible with Octave']);
            end

        case 'ds'

        case 'manual'

        otherwise
            assert(false,'this should not happen');
    end

    ds=cosmo_synthetic_dataset('type','timefreq','size','big','seed',0);
    ds.samples=randn(size(ds.samples));

    chan_to_select=cosmo_randperm(max(ds.fa.chan),ceil(rand()*3+1));
    freq_to_select=cosmo_randperm(max(ds.fa.freq),ceil(rand()*3+1));

    m=cosmo_match(ds.fa.chan,chan_to_select) & ...
            cosmo_match(ds.fa.freq,freq_to_select);
    ds=cosmo_slice(ds,m,2);
    ds=cosmo_dim_prune(ds);

    y=cosmo_meeg_baseline_correct(ds,interval,method);

    % (unsupported in octave)
    switch reference
        case 'ft'
            ft=cosmo_map2meeg(ds);

            opt=struct();
            opt.baseline=interval;
            opt.baselinetype=method;

            ft_bl=ft_freqbaseline(opt,ft);
            x=cosmo_meeg_dataset(ft_bl);

        case 'ds'
            msk=cosmo_dim_match(ds,'time',...
                        @(t) t>=min(interval) & t<=max(interval));
            ds_ref=cosmo_slice(ds,msk,2);
            x=cosmo_meeg_baseline_correct(ds,ds_ref,method);

        case 'manual'
            msk=cosmo_dim_match(ds,'time',...
                        @(t) t>=min(interval) & t<=max(interval));
            ds_ref=cosmo_slice(ds,msk,2);

            x=ds;

            for chan=1:max(ds.fa.chan)
                for freq=1:max(ds.fa.freq)
                    msk=ds.fa.chan==chan & ds.fa.freq==freq;
                    s=ds.samples(:,msk);

                    ref_msk=ds_ref.fa.chan==chan & ds_ref.fa.freq==freq;
                    r=mean(ds_ref.samples(:,ref_msk),2);

                    switch method
                        case 'absolute'
                            v=bsxfun(@minus,s,r);

                        case 'relative'
                            v=bsxfun(@rdivide,s,r);

                        case 'relchange'
                            v=bsxfun(@rdivide,bsxfun(@minus,s,r),r);


                        otherwise
                            error('not supported: %s', method);
                    end

                   x.samples(:,msk)=v;
                end
            end


        otherwise
            assert(false)

    end

    x_unq=cosmo_index_unique({x.fa.time,x.fa.chan});
    y_unq=cosmo_index_unique({y.fa.time,y.fa.chan});

    n=numel(x_unq);
    max_n_to_choose=10;
    n_to_choose=min(max_n_to_choose,n);
    rp=cosmo_randperm(n,n_to_choose);
    assert(numel(x_unq)==numel(y_unq));
    for j=1:n_to_choose;
        idx=rp(j);
        x_sel=cosmo_slice(x,x_unq{idx},2,false);
        y_sel=cosmo_slice(y,y_unq{idx},2,false);

        p=x_sel.samples;
        q=y_sel.samples;

        desc=sprintf('method %s, reference %s',method,reference);
        assertElementsAlmostEqual(p,q,...
                        'relative',1e-6,desc);
        assertEqual(x_sel.fa,y_sel.fa);

    end

    assertEqual(x.a.fdim,y.a.fdim);


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

function test_meeg_baseline_correct_nonmatching_sa
    ds=cosmo_synthetic_dataset('size','big','ntargets',8,...
                            'nchunks',1,'type','timelock');
    nsamples=size(ds.samples,1);

    while true
        rp=cosmo_randperm(nsamples);
        if ~isequal(rp,1:nsamples)
            break;
        end
    end
    ds_ref=cosmo_slice(ds,rp);
    assertExceptionThrown(@()cosmo_meeg_baseline_correct(...
                            ds,ds_ref,'relative'),'');


function test_meeg_baseline_correct_nonmatching_fa
    ds_big=cosmo_synthetic_dataset('size','big','ntargets',8,...
                            'nchunks',1,'type','timefreq');
    ds=cosmo_slice(ds_big,ds_big.fa.chan<=2 & ds_big.fa.freq<=3,2);
    ds_ref=cosmo_slice(ds_big,ds_big.fa.chan<=3 & ds_big.fa.freq<=2,2);

    assertExceptionThrown(@()cosmo_meeg_baseline_correct(...
                                        ds,ds_ref,'relative'),'');


function test_meeg_baseline_correct_illegal_inputs
    bc=@cosmo_meeg_baseline_correct;
    aet=@assertExceptionThrown;
    ds=cosmo_synthetic_dataset('type','timefreq','size','tiny');

    if cosmo_wtf('is_matlab')
        v=cosmo_wtf('version');
        is_prior_to_2012b=str2num(v(1))<=7;

        if is_prior_to_2012b
            id_missing_arg='MATLAB:inputArgUndefined';
        else
            id_missing_arg='MATLAB:minrhs';
        end
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



