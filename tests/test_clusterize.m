function test_suite = test_clusterize()
    initTestSuite

function test_clusterize_basics
    ds=cosmo_synthetic_dataset('size','normal','ntargets',1,'nchunks',1);
    nh=cosmo_cluster_neighborhood(ds,'progress',false);

    x=ds.samples;
    ds.samples=x>2;
    cl1=cosmo_clusterize(ds,nh);
    assertEqual(cl1,{[9;12],10,19});
    mx=cosmo_convert_neighborhood(nh,'matrix');
    cl2=cosmo_clusterize(ds.samples,mx);
    assertEqual(cl1,cl2);
    nb=cosmo_convert_neighborhood(nh,'cell');
    cl3=cosmo_clusterize(ds.samples,nb);
    assertEqual(cl1,cl3);

    ds.samples=round(x/2);
    cl3=cosmo_clusterize(ds,nh);
    assertEqual(cl3,{[ 1 2 5 10 13 19 20 23 25 26 29 15 18 21 24 27]',...
                    [3 6]',[9 12]',22});

    % test exceptions
    aet=@(x)assertExceptionThrown(@()cosmo_clusterize(x{:}),'');
    aet({'foo'});
    aet({ds,[]});
    aet({ds,-1});
    aet({'foo',nh});
    aet({zeros([2 2 2 ]),nh});
    aet({cosmo_stack({ds,ds}),nh});
