function test_suite = test_split
% tests for cosmo_split
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_split_()
    ds=cosmo_synthetic_dataset();
    sp1=cosmo_split(ds,'chunks');

    for k=1:numel(sp1)
        s=sp1{k};
        assertEqual(s, cosmo_slice(ds,(k*2+[-1 0])));
        assert(all(s.sa.chunks==k));
    end

    sp2=cosmo_split(ds,'targets');

    for k=1:numel(sp2)
        s=sp2{k};
        assertEqual(s, cosmo_slice(ds,k+[0 2 4]));
    end

    sp3=cosmo_split(ds,{'targets'});
    assertEqual(sp2,sp3);

    sp4=cosmo_split(ds,{'targets'},1);
    assertEqual(sp2,sp4);

    sp5=cosmo_split(ds,'i',2);

    for k=1:numel(sp5)
        s=sp5{k};
        assertEqual(s, cosmo_slice(ds,k+[0 3],2));
    end

    sp6=cosmo_split(ds,{'chunks','targets'});
    for k=1:numel(sp5)
        s=sp6{k};
        assertEqual(s, cosmo_slice(ds,k,1));
    end

    sp7=cosmo_split(ds,{'j','i','k'},2);
    for k=1:numel(sp5)
        s=sp7{k};
        assertEqual(s, cosmo_slice(ds,k,2));
    end

    assertEqual(cosmo_split(ds,[],1),{ds});
    assertEqual(cosmo_split(ds,[],2),{ds});

    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_split(varargin{:}),'');
    aet(ds,'i',1);
    aet(ds,'chunks',2);
    aet(ds,'chunks',3);

    ds.sa.targets=[ds.sa.targets ds.sa.targets];
    assertExceptionThrown(@()cosmo_split(ds,'targets',1),'');

    x=struct();
    x.samples=randn(4);
    aet(x,'chunks');
    x.sa=struct();
    aet(x,'chunks');
