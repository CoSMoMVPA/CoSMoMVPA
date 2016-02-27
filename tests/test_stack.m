function test_suite=test_stack
% tests for cosmo_stack
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_stack_samples

    ds=cosmo_synthetic_dataset();
    ds1=cosmo_slice(ds,[2 1 4 3 6 5]);
    ds2=cosmo_slice(ds,6:-1:1,2);



    % test first dimension
    s=cosmo_stack({ds,ds1});
    assertEqual(s.samples,[ds.samples;ds1.samples])
    assertEqual(s.sa.targets,[ds.sa.targets;ds1.sa.targets]);
    assertEqual(s.fa,ds1.fa);

    s2=cosmo_stack({ds,ds2},1,'drop_nonunique');
    assertEqual(fieldnames(s2.fa),{'k'});
    assertEqual(s2.samples,[ds.samples;ds2.samples]);
    assertExceptionThrown(@()cosmo_stack({ds,ds2},1,'unique'),'');
    assertExceptionThrown(@()cosmo_stack({ds,ds2}),'');


    s3=cosmo_stack({ds,ds2},1,'drop');
    assertTrue(isempty(fieldnames(s3.fa)));
    assertEqual(s3.sa,s2.sa);

    s4=cosmo_stack({ds,ds2},1,'drop_nonunique');
    assertEqual(s2,s4);

    s5=cosmo_stack({ds,ds2},1,2);
    assertEqual(s5.fa,ds2.fa);

    % should properly deal with NaNs
    ds.fa.i(2:4)=NaN;
    ds1.fa.i(2:4)=NaN;
    s=cosmo_stack({ds,ds1});
    assertEqual(s.fa,ds1.fa);



function test_stack_features
    ds=cosmo_synthetic_dataset();
    ds1=cosmo_slice(ds,6:-1:1,2);
    ds2=cosmo_slice(ds,[2 1 4 3 6 5]);



    % test second dimension
    s=cosmo_stack({ds,ds1},2,'drop_nonunique');
    assertEqual(s.samples,[ds.samples ds1.samples])
    assertEqual(s.fa.i,[ds.fa.i ds1.fa.i]);
    assertEqual(s.sa,ds1.sa);

    s2=cosmo_stack({ds,ds2},2,'drop_nonunique');
    assertEqual(fieldnames(s2.sa),{'chunks'});
    assertEqual(s2.samples,[ds.samples ds2.samples]);
    assertExceptionThrown(@()cosmo_stack({ds,ds2},2,'unique'),'');
    assertExceptionThrown(@()cosmo_stack({ds,ds2},2),'');


    s3=cosmo_stack({ds,ds2},2,'drop');
    assertTrue(isempty(fieldnames(s3.sa)));
    assertEqual(s3.fa,s2.fa);

    s4=cosmo_stack({ds,ds2},2,'drop_nonunique');
    assertEqual(s2,s4);

    s5=cosmo_stack({ds,ds2},2,2);
    assertEqual(s5.sa,ds2.sa);

    s6=cosmo_stack({ds},1);
    assertEqual(s6,ds);

    % should properly deal with NaNs
    ds.sa.targets(2:4)=NaN;
    ds1.sa.targets(2:4)=NaN;
    s=cosmo_stack({ds,ds},2);
    assertEqual(s.sa,ds1.sa);

function test_stack_exceptions
    % test exceptions
    ds=cosmo_synthetic_dataset();
    aet=@(varargin)assertExceptionThrown(@()cosmo_stack(varargin{:}),'');
    aet('foo');
    aet({ds},3);
    aet({ds},1,'foo');

    % sample size mismatch
    ds1=ds;
    ds1.samples=ones(1,5);
    aet({ds,ds1});

    % .sa size mismatch
    ds1=ds;
    ds1.sa.targets=1;
    aet({ds,ds1});

    % non-matching elements
    ds1=ds;
    ds2=ds;
    ds2.sa.targets=ds2.sa.targets(end:-1:1);
    aet({ds1,ds2},2);

    ds2=ds;
    ds2.fa.i=ds2.fa.i(end:-1:1);
    aet({ds1,ds2},1);


