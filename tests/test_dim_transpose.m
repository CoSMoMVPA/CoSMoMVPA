function test_suite=test_dim_transpose
% tests for cosmo_dim_transpose
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_dim_transpose_basics()
    x=cosmo_synthetic_dataset('size','normal');
    [nsamples,nfeatures]=size(x.samples);
    x.samples(:)=1:(nsamples*nfeatures);
    x=cosmo_slice(x,nfeatures:-1:1,2);

    y=cosmo_dim_transpose(x,'j',1);
    assertEqual(y,cosmo_dim_transpose(x,'j'));

    z=cosmo_dim_transpose(x,{'k','i','j'},1);
    assertEqual(z,cosmo_dim_transpose(x,{'k','i','j'}));
    assertEqual(z,cosmo_dim_transpose(x,{'k','i','j'},1,0));

    rps=ceil(rand(1,10)*nsamples);
    for rp=rps
        [p,q]=find(x.samples==rp);
        [pp,qq]=find(y.samples==rp);
        [ppp,qqq]=find(z.samples==rp);

        assertEqual(x.fa.i(q),y.fa.i(qq));
        assertEqual(x.fa.j(q),y.sa.j(pp));
        assertEqual(x.fa.k(q),y.fa.k(qq));

        assertEqual(x.fa.i(q),z.sa.i(ppp));
        assertEqual(x.fa.j(q),z.sa.j(ppp));
        assertEqual(x.fa.k(q),z.sa.k(ppp));
    end


    yx=cosmo_dim_transpose(y,'j',2,2);
    zx=cosmo_dim_transpose(z,{'i','j','k'});

    assert_same_samples_with_permutation(x,yx);
    assert_same_samples_with_permutation(x,zx);

function test_dim_transpose_exceptions()
    x=cosmo_synthetic_dataset();
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_dim_transpose(varargin{:}),'');

    aet(x,'foo')
    aet(x,1);
    aet(x,'i',2);
    aet(x,'i',1,2);
    x.a.sdim=x.a.fdim;
    x.sa.i=x.fa.i';
    aet(x,'i',1);

function test_dim_transpose_nonmatching_attr()
    x=struct();
    x.samples=[1;2;3];
    x.a.sdim.labels={'i'};
    x.a.sdim.values={[10 11]};
    x.sa.i=[2;2;2];
    x.sa.j=1+[1;2;3];
    x.fa=struct();

    y=struct();
    y.samples=[4;5;6];
    y.a.sdim.labels={'i'};
    y.a.sdim.values={[10 11]};
    y.sa.i=[1;1;1];
    y.sa.j=1+[2;3;1];
    y.fa=struct();

    xy=cosmo_stack({x,y});


    assertExceptionThrown(@()cosmo_dim_transpose(xy,'i',2),'');




function assert_same_samples_with_permutation(x,y)
    nsamples=size(x.samples,1);
    ii=max(ceil(x.samples/nsamples));
    jj=max(ceil(y.samples/nsamples));

    mp=jj;
    mp(jj)=ii;

    yy=cosmo_slice(y,mp,2);
    assertEqual(x.samples,yy.samples);
    yy.fa=rmfield(yy.fa,'transpose_ids');
    assertEqual(x.fa,yy.fa);
    y.sa=rmfield(y.sa,'transpose_ids');
    assertEqual(x.sa,y.sa);



