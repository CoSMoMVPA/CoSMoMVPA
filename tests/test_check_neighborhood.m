function test_suite=test_check_neighborhood
% tests for cosmo_check_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite

function test_check_neighborhood_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_check_neighborhood(varargin{:}),'');
    is_ok=@cosmo_check_neighborhood;

    % test four possible scenario's:
    % 1) two arguments (nh and ds), nh has .origin
    % 2) two arguments (nh and ds), nh does not have .origin
    % 3) one arguments nh, nh has .origin
    % 4) one arguments nh, nh does not have .origin

    ds=cosmo_synthetic_dataset();
    nh=[];
    aet(nh);
    nh=struct();
    aet(nh);
    aet(nh,ds);

    nh.fa=struct();
    nh.neighbors='foo';

    aet(nh,ds);
    aet_wo(nh,ds);
    aet_wo(nh);
    aet(nh);

    nh.neighbors={[1 2];3};
    nh.fa.i=[2 1];
    nh.a.vol.dim=[1 2 1];
    nh.origin.a=ds.a;
    nh.origin.fa=ds.fa;
    is_ok(nh,ds);
    ok_wo(nh,ds);
    ok_wo(nh);
    is_ok(nh);



    nh.neighbors={[1;2];3};
    aet(nh,ds);
    aet_wo(nh,ds);
    aet_wo(nh);
    aet(nh);


    nh.neighbors={[1 2],3};
    aet(nh,ds);
    aet_wo(nh,ds);
    aet(nh);

    nh.neighbors={[1 2];3;4};
    aet(nh,ds);
    aet_wo(nh,ds);
    aet_wo(nh);
    aet(nh);

    nh.neighbors={[1 2];3};
    nh.foo=struct();
    aet(nh,ds);
    aet_wo(nh,ds);
    aet_wo(nh);
    aet(nh);
    nh=rmfield(nh,'foo');

    nh.neighbors={[.5 1];3};
    aet(nh,ds);
    aet_wo(nh,ds);
    aet_wo(nh);
    aet(nh);

    nh.neighbors={[.5 1];struct()};
    aet(nh,ds);
    aet_wo(nh,ds);
    aet_wo(nh);
    aet(nh);

    nh.neighbors={[1 2];7};
    aet(nh,ds);
    aet_wo(nh,ds);
    ok_wo(nh);
    is_ok(nh); % should pass

    nh.neighbors={[1 2];3};
    is_ok(nh,ds); % should pass
    ok_wo(nh,ds);
    is_ok(nh); % should pass

    nh.origin.fa=ds.fa;
    nh.origin.a=ds.a;
    nh.fa=ds.fa;
    nh.a=ds.a;
    nh.neighbors=num2cell(1:6)';
    is_ok(nh,ds); % should pass
    ok_wo(nh,ds);
    ok_wo(nh);
    is_ok(nh);

    nh.origin.fa=rmfield(nh.fa,'i');
    aet(nh,ds);
    ok_wo(nh,ds);
    ok_wo(nh);
    is_ok(nh); % should pass

    nh.origin.a.fdim.labels=nh.a.fdim.labels(2:end);
    aet(nh,ds);
    ok_wo(nh,ds);
    ok_wo(nh);
    is_ok(nh); % should pass

    nh.origin.a.fdim.values=nh.a.fdim.values(2:end);
    aet(nh,ds);
    ok_wo(nh,ds);
    ok_wo(nh);
    is_ok(nh); % should pass
    assertFalse(is_ok(nh,false,ds)); % should pass
    assertFalse(is_ok(nh,ds,false)); % should pass

    ds.a.fdim.values=ds.a.fdim.values(2:end);
    ds.a.fdim.labels=ds.a.fdim.labels(2:end);
    is_ok(nh,ds); % should pass
    ok_wo(nh,ds);
    ok_wo(nh);
    is_ok(nh); % should pass

    ds2=ds;
    ds2.a.vol.dim=[2 2 2];
    aet(nh,ds2);
    ok_wo(nh,ds2);
    ok_wo(nh);
    is_ok(nh);

    ds=cosmo_slice(ds,3:6);
    nh=struct();
    nh.sa=ds.sa;
    nh.neighbors={1;2};
    nh.origin.a=ds.a;
    aet(nh,ds);
    aet_wo(nh,ds);
    aet_wo(nh);
    aet(nh);

    % should pass
    nh.neighbors={1;2;4;3};
    is_ok(nh,ds);
    ok_wo(nh,ds);
    ok_wo(nh);
    is_ok(nh);

    % cannot have both .sa and .fa
    nh2=nh;
    nh2.fa=struct();
    aet(nh2,ds);



    % different .a.vol.dim
    nh2=nh;
    nh2.origin.a.vol.dim=[4 0 0];
    aet(nh2,ds);
    ok_wo(nh2,ds);
    ok_wo(nh2);
    is_ok(nh2);

    % some exceptions for show_warning
    aet(ds,nh,'show_warning');
    aet(ds,nh,'foo');

function nh=remove_origin(nh)
    if isfield(nh,'origin')
        nh=rmfield(nh,'origin');
    end

function aet_wo(nh,varargin)
    % assert exception thrown without origin
    nh=remove_origin(nh);

    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    assertExceptionThrown(@()...
                cosmo_check_neighborhood(nh,varargin{:}),'');

function ok_wo(nh,varargin)
    % is ok without origin
    nh=remove_origin(nh);

    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');
    cosmo_check_neighborhood(nh,varargin{:});
