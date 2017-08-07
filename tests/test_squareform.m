function test_suite = test_squareform
% tests for cosmo_squareform
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
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

        helper_assert_squareform_equal_to_matlab(data);
        helper_assert_squareform_equal_to_matlab(data,'tomatrix');
        helper_assert_squareform_equal_to_matlab(data','tomatrix');

        mx=squareform(data);
        helper_assert_squareform_equal_to_matlab(mx);
        helper_assert_squareform_equal_to_matlab(mx,'tovector');
    end

function helper_assert_squareform_equal_to_matlab(varargin)
    assertEqual(squareform(varargin{:}),cosmo_squareform(varargin{:}));


function test_squareform_random_data_without_nans()
    helper_test_squareform_with_random_data(false);

function test_squareform_random_data_with_nans()
    helper_test_squareform_with_random_data(true);

function helper_test_squareform_with_random_data(has_nan)
    for side=1:10
        data=randn(side);
        data=data+data';
        data=data-diag(diag(data));

        if has_nan
            if side==1
                continue;
            end

            data(side,1)=NaN;
            data(1,side)=NaN;
        end

        data_sq=cosmo_squareform(data,'tovector');
        nelem=numel(data_sq);
        assertEqual(nelem,side*(side-1)/2);

        counter=0;
        for col=1:(side-1)
            for row=(col+1):side
                counter=counter+1;
                assertEqual(data(row,col),data_sq(counter));
            end
        end

        data_back=cosmo_squareform(data_sq,'tomatrix');
        if side==1
            assert(isempty(data_back));
        else
            assertEqual(data,data_back);
        end
    end






