function test_suite=test_check_neighborhood
    initTestSuite

function test_check_neighborhood_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_check_neighborhood(varargin{:}),'');
    is_ok=@cosmo_check_neighborhood;

    ds=cosmo_synthetic_dataset();
    nh=[];
    aet(nh);
    nh=struct();
    aet(nh);
    nh.fa=struct();
    nh.neighbors='foo';
    aet(nh);

    nh.neighbors={[1 2];3};
    nh.fa.i=[2 1];
    nh.a.vol.dim=[1 2 1];
    nh.origin.a=ds.a;
    nh.origin.fa=ds.fa;
    is_ok(nh); % should pass

    nh.neighbors={[1;2];3};
    aet(nh,ds);
    aet(nh);

    nh.neighbors={[1 2],3};
    aet(nh,ds);
    aet(nh);

    nh.neighbors={[1 2];3;4};
    aet(nh,ds);
    aet(nh);

    nh.neighbors={[1 2];3};
    nh.foo=struct();
    aet(nh,ds);
    aet(nh);
    nh=rmfield(nh,'foo');

    nh.neighbors={[.5 1];3};
    aet(nh,ds);
    aet(nh);

    nh.neighbors={[.5 1];struct()};
    aet(nh,ds);
    aet(nh);

    nh.neighbors={[1 2];7};
    aet(nh,ds);
    is_ok(nh); % should pass

    nh.neighbors={[1 2];3};
    is_ok(nh,ds); % should pass
    is_ok(nh); % should pass

    nh.origin.fa=ds.fa;
    nh.origin.a=ds.a;
    nh.fa=ds.fa;
    nh.a=ds.a;
    nh.neighbors=num2cell(1:6)';
    is_ok(nh,ds); % should pass

    nh.origin.fa=rmfield(nh.fa,'i');
    aet(nh,ds);
    is_ok(nh); % should pass

    nh.origin.a.fdim.labels=nh.a.fdim.labels(2:end);
    aet(nh,ds);
    is_ok(nh); % should pass

    nh.origin.a.fdim.values=nh.a.fdim.values(2:end);
    aet(nh,ds);
    is_ok(nh); % should pass
    assertFalse(is_ok(nh,false,ds)); % should pass
    assertFalse(is_ok(nh,ds,false)); % should pass

    ds.a.fdim.values=ds.a.fdim.values(2:end);
    ds.a.fdim.labels=ds.a.fdim.labels(2:end);
    is_ok(nh,ds); % should pass
    is_ok(nh,true); % should pass


    ds=cosmo_slice(ds,3:6);
    nh=struct();
    nh.sa=ds.sa;
    nh.neighbors={1;2};
    aet(nh);
    aet(nh,ds);

    nh.neighbors={1;2;4;3};
    is_ok(nh,ds); % should pass
    is_ok(nh); % should pass

