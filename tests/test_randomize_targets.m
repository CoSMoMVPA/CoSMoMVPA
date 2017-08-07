function test_suite = test_randomize_targets()
% tests for cosmo_randomize_targets
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_randomize_targets_basics()
    ds=cosmo_synthetic_dataset('ntargets',4,'nchunks',10);
    [x1,perm1]=cosmo_randomize_targets(ds);
    assertEqual(size(ds.sa.targets),[40 1])
    assertEqual(x1,ds.sa.targets(perm1))
    assertEqual(sort(perm1),(1:size(ds.samples,1))');

    x2=cosmo_randomize_targets(ds);
    assert(any(x1~=x2)); % probablity of failing less than 1e-13
    assert(any(x1~=ds.sa.targets));

    ds_small=cosmo_slice(ds,1:8);
    x3=cosmo_randomize_targets(ds_small,'seed',1);
    assertEqual(x3,[ 3 4 1 2 2 1 3 4]');

    x4=cosmo_randomize_targets(ds_small,'seed',314);
    assertEqual(x4,[ 3 2 4 1 4 3 2 1]');

    ds_single_target=cosmo_slice(ds,1:4:20);
    x5=cosmo_randomize_targets(ds_single_target,'seed',314);
    assertEqual(x5,ones(5,1));

    ds_between=cosmo_slice(ds,1:5:40);
    x6=cosmo_randomize_targets(ds_between,'seed',1);
    assertEqual(x6,[3 2 1 3 4 4 1 2]');
    x7=cosmo_randomize_targets(ds_between);
    assertEqual(histc(x7,1:4),[2 2 2 2]');

    % test exceptions
    aet=@(varargin)assertExceptionThrown(@()cosmo_randomize_targets(...
    varargin{:}),'');

    ds_missing=cosmo_slice(ds,1:3:20);
    aet(ds_missing);

    ds.sa=rmfield(ds.sa,'targets');
    aet(ds);

    ds=rmfield(ds,'sa');
    aet(ds);
