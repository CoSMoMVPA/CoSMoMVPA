function test_suite = test_rand()
% tests for cosmo_rand
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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



function test_rand_exceptions
    aet=@(varargin) assertExceptionThrown(@()cosmo_rand(varargin{:}),'');
    aet(2,2,'foo')
    aet(2,2,'foo',2)
    aet(2,2,'seed',[1 2])
    aet(2,2,'seed',-1)
    aet(2,2,'seed',NaN)
    aet(-2,2);
    aet(NaN,2);

