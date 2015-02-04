function test_suite=test_dim_transpose
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
    assertEqual(z,cosmo_dim_transpose(x,{'k','i','j'},1,-1));

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


function assert_same_samples_with_permutation(x,y)
    nsamples=size(x.samples,1);
    ii=max(ceil(x.samples/nsamples));
    jj=max(ceil(y.samples/nsamples));

    mp=jj;
    mp(jj)=ii;

    yy=cosmo_slice(y,mp,2);
    assertEqual(x.samples,yy.samples);
    assertEqual(x.fa,yy.fa);
    assertEqual(x,yy);



