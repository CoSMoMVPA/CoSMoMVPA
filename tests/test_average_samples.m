function test_suite = test_average_samples
    initTestSuite;

function test_average_samples_
    ds=cosmo_synthetic_dataset();


    a=cosmo_average_samples(ds);

    assertElementsAlmostEqual(sort(a.samples), sort(ds.samples));
    assertElementsAlmostEqual(sort(a.samples(:,3)), sort(ds.samples(:,3)));


    a=cosmo_average_samples(ds,'ratio',.5);

    assertElementsAlmostEqual(sort(a.samples), sort(ds.samples));
    assertElementsAlmostEqual(sort(a.samples(:,3)), sort(ds.samples(:,3)));


    % check wrong inputs
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_average_samples(varargin{:}),'');

    aet(ds,'ratio',.1);
    aet(ds,'ratio',3);
    aet(ds,'ratio',.5,'count',2);

    ds.sa.chunks(:)=1;
    a=cosmo_average_samples(ds,'ratio',.5);
    a_=cosmo_fx(a,@(x)mean(x,1),'targets');
    assertEqual(a,a_);

    cosmo_check_dataset(a);

    ds=cosmo_slice(ds,3,2);
    ns=size(ds.samples,1);
    ds.samples=ds.sa.targets*1000+(1:ns)';

    a=cosmo_average_samples(ds,'ratio',.5,'nrep',10);

    % no mixing of different targets
    delta=a.samples/1000-a.sa.targets;
    assertTrue(all(.00099<=delta & delta<.05));
    assertElementsAlmostEqual(delta*3000,round(delta*3000));

    a=cosmo_average_samples(ds,'count',3,'nrep',10);
    % no mixing of different targets
    delta=a.samples/1000-a.sa.targets;
    assertTrue(all(.00099<=delta & delta<.05));
    assertElementsAlmostEqual(delta*3000,round(delta*3000));

