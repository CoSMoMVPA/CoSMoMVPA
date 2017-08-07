function test_suite = test_rand()
% tests for cosmo_rand
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_rand_basics
    x1=cosmo_rand();
    x2=cosmo_rand();
    assert(x1~=x2);

    x3=cosmo_rand('seed',217);
    x4=cosmo_rand('seed',217);
    assert(x1~=x3);
    assert(x2~=x3);
    assert(x3==x4);

    x5=cosmo_rand('seed',218);
    assert(x3~=x5);

    assert(isscalar(x5));
    x6=cosmo_rand(1);
    assert(isscalar(x6));

    assertEqual(size(cosmo_rand(3)),[3 3])
    assertEqual(size(cosmo_rand(3,'seed',2)),[3 3])
    assertEqual(size(cosmo_rand(3,3)),[3 3])
    assertEqual(size(cosmo_rand(1,2,3)),[1,2,3])
    assertEqual(size(cosmo_rand([1,2,3])),[1,2,3])
    assertEqual(size(cosmo_rand([1,2,3])),[1,2,3])

    x7=cosmo_rand('single');
    assertEqual(class(x7),'single');
    seed=ceil(rand()*1e5);
    sz=ceil(3*rand(1,4));
    x8=cosmo_rand(sz,'single','seed',seed);
    x8b=cosmo_rand(sz,'single','seed',seed);
    assertEqual(x8,x8b);
    assertEqual(class(x8),'single');

    x9=cosmo_rand(sz,'double','seed',seed);
    x9b=cosmo_rand(sz,'double','seed',seed);
    assertEqual(x8,x8b);
    assertEqual(class(x8),'single');

    assertElementsAlmostEqual(x8,single(x9));



function test_rand_exceptions
    aet=@(varargin) assertExceptionThrown(@()cosmo_rand(varargin{:}),'');
    aet(2,2,'foo');
    aet(2,2,'foo',2);
    aet(2,2,'single',2);
    aet(2,2,'double',2);
    aet(2,2,'single','double');
    aet(2,2,'double','single');
    aet(2,2,'double','double');
    aet(2,2,'signle','single');
    aet(2,2,'seed',[1 2]);
    aet(2,2,'seed',-1);
    aet(2,2,'seed',NaN);
    aet(-2,2);
    aet(NaN,2);

