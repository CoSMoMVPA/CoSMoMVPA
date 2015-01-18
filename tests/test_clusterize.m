function test_suite = test_clusterize()
    initTestSuite

function test_clusterize_basics
    ds=cosmo_synthetic_dataset('size','normal','ntargets',1,'nchunks',1);
    sample=ds.samples;

    nh_struct=cosmo_cluster_neighborhood(ds,'progress',false);
    nh=cosmo_convert_neighborhood(nh_struct,'matrix');

    x=sample;
    sample=x>2;
    cl1=cosmo_clusterize(sample,nh);
    assertEqual(cl1,{[9;12],10,19});
    nb=cosmo_convert_neighborhood(nh,'cell');

    sample=round(x/2);
    cl2=cosmo_clusterize(sample,nh);
    assertEqual(cl2,{[ 1 2 5 10 13 19 20 23 25 26 29 15 18 21 24 27]',...
                    [3 6]',[9 12]',22});

    % test exceptions
    aet=@(x)assertExceptionThrown(@()cosmo_clusterize(x{:}),'');
    aet({'foo',[]});
    aet({sample,[]});
    aet({sample,-1});
    aet({'foo',nh});
    aet({zeros([2 2 2 ]),nh});
    aet({[sample;sample],nh});
