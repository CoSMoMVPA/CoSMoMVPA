function test_suite = test_squareform
% tests for cosmo_squareform
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_squareform_()
    vec=1:6;
    mx=[0 1 2 3; 1 0 4 5; 2 4 0 6; 3 5 6 0];

    sf=@cosmo_squareform;

    % numeric input
    assertElementsAlmostEqual(sf(vec),mx);
    assertElementsAlmostEqual(sf(vec,'tomatrix'),mx);
    assertElementsAlmostEqual(sf(mx),vec);
    assertElementsAlmostEqual(sf(mx,'tovector'),vec);

    % logical input
    vec2=logical(vec);
    mx2=logical(mx);
    assertEqual(sf(vec2),mx2);
    assertEqual(sf(vec2,'tomatrix'),mx2);
    assertEqual(sf(mx2),vec2);
    assertEqual(sf(mx2,'tovector'),vec2);

    % exceptions
    assertExceptionThrown(@() sf(vec,'foo'),'');
    assertExceptionThrown(@() sf(mx,'foo'),'');
    assertExceptionThrown(@() sf(vec,struct()),...
                                    '');
    assertExceptionThrown(@() sf(struct()),'');
    assertExceptionThrown(@() sf(struct(),'tovector'),'');
    assertExceptionThrown(@() sf(struct(),'tomatrix'),'');
    assertExceptionThrown(@() sf(zeros(2,3),'tovector'),'');
    assertExceptionThrown(@() sf(zeros(2),'tomatrix'),'');
    assertExceptionThrown(@() sf(zeros([2,2,2])),'');
    assertExceptionThrown(@() sf(zeros([2,2,2]),'tovector'),'');
    assertExceptionThrown(@() sf(zeros([2,2,2]),'tomatrix'),'');

    assertExceptionThrown(@() sf([vec 1]),'');
    assertExceptionThrown(@() sf([vec 1],'tomatrix'),'');
    assertExceptionThrown(@() sf(cell(0,0),'tomatrix'),'');
    assertExceptionThrown(@() sf(cell(0,0),'tovector'),'');
    assertExceptionThrown(@() sf(cell(0,0),''),'');


    assertExceptionThrown(@() sf(eye(4)+mx),'');
    assertExceptionThrown(@() sf(eye(4)+mx,'tovector'),'');

    mx(2,1)=3;
    assertExceptionThrown(@() sf(mx,'tovector'),'');

function test_squareform_matlab_agreement()
    if cosmo_wtf('is_octave') || ~cosmo_check_external('@stats',false)
        cosmo_notify_test_skipped('Matlab''s squareform is not available');
        return
    end

    for side=1:10
        n=side*(side-1)/2;
        data=rand(n,1);

        assert_squareform_equal(data);
        assert_squareform_equal(data,'tomatrix');
        assert_squareform_equal(data','tomatrix');

        mx=squareform(data);
        assert_squareform_equal(mx);
        assert_squareform_equal(mx,'tovector');
    end

function assert_squareform_equal(varargin)
    assertEqual(squareform(varargin{:}),cosmo_squareform(varargin{:}));



