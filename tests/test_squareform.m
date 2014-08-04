function test_suite = test_squareform
    initTestSuite;


function test_squareform_()
    vec=1:6;
    mx=[0 1 2 3; 1 0 4 5; 2 4 0 6; 3 5 6 0];

    sf=@cosmo_squareform;


    assertElementsAlmostEqual(sf(vec),mx);
    assertElementsAlmostEqual(sf(vec),mx,'tomatrix');
    assertElementsAlmostEqual(sf(mx),vec);
    assertElementsAlmostEqual(sf(mx),vec,'tovector');

    assertExceptionThrown(@() sf(vec,'foo'),'');
    assertExceptionThrown(@() sf(mx,'foo'),'');
    assertExceptionThrown(@() sf(vec,struct()),...
                                    'MATLAB:badSwitchExpression');
    assertExceptionThrown(@() sf(struct()),'');
    assertExceptionThrown(@() sf(struct(),'tovector'),'');
    assertExceptionThrown(@() sf(struct(),'tomatrix'),'');
    assertExceptionThrown(@() sf(zeros([2,2,2])),'');
    assertExceptionThrown(@() sf(zeros([2,2,2]),'tovector'),'');
    assertExceptionThrown(@() sf(zeros([2,2,2]),'tomatrix'),'');

    assertExceptionThrown(@() sf([vec 1]),'');
    assertExceptionThrown(@() sf([vec 1],'tomatrix'),'');

    assertExceptionThrown(@() sf(eye(4)+mx),'');
    assertExceptionThrown(@() sf(eye(4)+mx,'tovector'),'');

    mx(2,1)=3;
    assertExceptionThrown(@() sf(mx,'tovector'),'');



