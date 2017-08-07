function test_suite = test_measure_clusters()
% tests for cosmo_measure_clusters
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite

function test_measure_clusters_statfun
    samples=[-1 2 1 1 NaN 2 2];
    nbrhood_mat=[ 1 1 2 3 4 5 6
                  2 2 3 4 5 6 7
                  0 3 4 5 6 7 0];

    m=@(x) cosmo_measure_clusters(samples,nbrhood_mat,x{:});
    aoe=@(x,v)assertElementsAlmostEqual(m(x),v,'relative',1e-4);

    aoe({'tfce','dh',.1},[ 0 2.7518 0.6668 0.6668 0 3.4931 3.4931])
    aoe({'tfce','dh',.05},[ 0 2.7935 0.5348 0.5348 0 3.6310 3.6310])
    aoe({'tfce','dh',3},zeros(1,7));
    aoe({'tfce','dh',.05,'E',1},[0 3.1850 0.9263 0.9263 0 5.1350 5.1350])
    aoe({'tfce','dh',.05,'H',1},[0 2.2977 0.8227 0.8227 0 2.7577 2.7577])
    aoe({'tfce','dh',.05,'H',1,'feature_sizes',2*ones(1,7)},...
                                [ 0 3.2495 1.1635 1.1635 0 3.9000 3.9000])
    aoe({'max','threshold',1},[ 0 2 2 2 0 2 2])
    aoe({'max','threshold',2},[ 0 2 0 0 0 2 2])
    aoe({'max','threshold',3},zeros(1,7));
    aoe({'maxsize','threshold',1},[ 0 3 3 3 0 2 2])
    aoe({'maxsize','threshold',2},[0 1 0 0 0 2 2])
    aoe({'maxsize','threshold',3},zeros(1,7));
    aoe({'maxsum','threshold',1},[ 0 4 4 4 0 4 4])
    aoe({'maxsum','threshold',2},[ 0 2 0 0 0 4 4])
    aoe({'maxsum','threshold',3},zeros(1,7));


function test_measure_clusters_infinity
    samples=[-Inf Inf Inf 1 NaN 2 Inf];
    nbrhood_mat=[ 1 1 2 3 4 5 6
                  2 2 3 4 5 6 7
                  0 3 4 5 6 7 0];

    m=@(x) cosmo_measure_clusters(samples,nbrhood_mat,x{:});
    aoe=@(x,v)assertElementsAlmostEqual(m(x),v,'relative',1e-4);

    aoe({'tfce','dh',.1},[ 0 Inf Inf 0.6668 0 3.4931 Inf]);
    aoe({'max','threshold',1},[ 0 Inf Inf Inf 0 Inf Inf]);
    aoe({'max','threshold',2},[ 0 Inf Inf 0 0 Inf Inf]);
    aoe({'max','threshold',3},[ 0 Inf Inf 0 0 0 Inf]);
    aoe({'maxsize','threshold',1},[ 0 3 3 3 0 2 2])
    aoe({'maxsize','threshold',2},[0 2 2 0 0 2 2])
    aoe({'maxsize','threshold',3},[0 2 2 0 0 0 1]);
    aoe({'maxsum','threshold',1},[ 0 Inf Inf Inf 0 Inf Inf])
    aoe({'maxsum','threshold',2},[ 0 Inf Inf 0 0 Inf Inf])
    aoe({'maxsum','threshold',3},[ 0 Inf Inf 0 0 0 Inf]);



function test_measure_clusters_exceptions()
    aet=@(x)assertExceptionThrown(@()cosmo_measure_clusters(x{:}),'');
    aet({ones(1,3),ones(1,4),'tfce','dh',.1})
    aet({ones(3,1),ones(1,3),'tfce','dh',.1})
    aet({ones(1,3),ones(3,1),'tfce','dh',.1})
    aet({struct(),ones(1,3),'tfce','dh',.1})
    aet({ones(1,3),struct(),'tfce','dh',.1})

    samples=[-1 2 1 1 0 2 2];
    nbrhood_mat=[ 1 1 2 3 4 5 6
     2 2 3 4 5 6 7
     0 3 4 5 6 7 0];
    m=@(x) cosmo_measure_clusters(samples,nbrhood_mat,x{:});
    aetw=@(x) assertExceptionThrown(@()m(x),'');

    aetw({'foo'})
    aetw({'tfce'})
    aetw({'tfce','threshold',1})
    aetw({'tfce','dh',-.1})
    aetw({'tfce','dh',[1 1]})
    aetw({'tfce','dh',.1,'E',-.1})
    aetw({'tfce','dh',.1,'E',[1 1]})
    aetw({'tfce','dh',.1,'H',-.1})
    aetw({'tfce','dh',.1,'H',[1 1]})

    aetw({'max','dh',1})
    aetw({'max','dh',1,'threshold',3})
    aetw({'max','dh',1,'feature_sizes',[]})
    aetw({'max','dh',1,'feature_sizes',3})









