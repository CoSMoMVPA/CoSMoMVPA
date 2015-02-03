function test_suite=test_check_neighborhood
    initTestSuite

function test_check_neighborhood_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_check_neighborhood(varargin{:}),'');
    nh=struct();
    aet(nh);
    nh.neighbors={[1 2];3};
    nh.fa.i=[2 1];
    nh.a.vol.dim=[1 2 1];
    cosmo_check_neighborhood(nh); % should pass

    nh.neighbors={[1;2];3};
    aet(nh);
    nh.neighbors={[1 2],3};
    aet(nh);
    nh.neighbors={[1 2];3;4};
    aet(nh);
    nh.neighbors={[1 2];3};
    nh.foo=struct();
    aet(nh);
    nh=rmfield(nh,'foo');

    nh.neighbors={[.5 1];3};
    aet(nh);
    nh.neighbors={[.5 1];struct()};
    aet(nh);


