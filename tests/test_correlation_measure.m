function test_suite=test_correlation_measure
    initTestSuite;

function test_correlation_measure_basis()
    ds3=cosmo_synthetic_dataset('nchunks',3,'ntargets',4);
    ds=cosmo_slice(ds3,ds3.sa.chunks<=2);

    ds.sa.chunks=ds.sa.chunks+10;
    ds.sa.targets=ds.sa.targets+20;
    x=ds.samples(ds.sa.chunks==11,:);
    y=ds.samples(ds.sa.chunks==12,:);

    cxy=atanh(corr(x',y'));

    diag_msk=eye(4)>0;
    c_diag=mean(cxy(diag_msk));
    c_off_diag=mean(cxy(~diag_msk));

    delta=c_diag-c_off_diag;

    c1=cosmo_correlation_measure(ds);
    assertElementsAlmostEqual(delta,c1.samples,'relative',1e-5);
    assertEqual(c1.sa.labels,{'corr'});

    c2=cosmo_correlation_measure(ds,'output','correlation');
    assertElementsAlmostEqual(reshape(cxy',[],1),c2.samples);
    assertEqual(kron((1:4)',ones(4,1)),c2.sa.half1);
    assertEqual(repmat((1:4)',4,1),c2.sa.half2);

    i=7;
    assertElementsAlmostEqual(cxy(c2.sa.half1(i),c2.sa.half2(i)),c2.samples(i));

    assertEqual({'half1','half2'},c2.a.sdim.labels);
    assertEqual({20+(1:4)',20+(1:4)'},c2.a.sdim.values);

    c3=cosmo_correlation_measure(ds,'output','one_minus_correlation');
    assertElementsAlmostEqual(1-c2.samples,c3.samples);
    assertEqual(c3.sa,c2.sa);

    c4=cosmo_correlation_measure(ds3,'output','mean_by_fold');
    %
    for j=1:3
        train_idxs=(3-j)*4+(1:4);
        test_idxs=setdiff(1:12,train_idxs);

        ds_sel=ds3;
        ds_sel.sa.chunks(train_idxs)=2;
        ds_sel.sa.chunks(test_idxs)=1;

        c5=cosmo_correlation_measure(ds_sel,'output','mean');
        assertElementsAlmostEqual(c5.samples, c4.samples(j));
    end

    % test permutations
    ds4=cosmo_synthetic_dataset('nchunks',2,'ntargets',10);
    rp=randperm(20);

    ds4_perm=cosmo_slice(ds4,rp);
    assertEqual(cosmo_correlation_measure(ds4),...
                    cosmo_correlation_measure(ds4_perm));
    opt=struct();
    opt.output='correlation';
    assertEqual(cosmo_correlation_measure(ds4,opt),...
                    cosmo_correlation_measure(ds4_perm,opt));



function test_correlation_measure_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_correlation_measure(varargin{:}),'');

    ds=cosmo_synthetic_dataset('nchunks',2);
    aet(ds,'template',eye(4));
    aet(ds,'output','foo');

    ds.sa.targets(:)=1;
    aet(ds);
    ds.sa.targets(1)=2;
    aet(ds);



