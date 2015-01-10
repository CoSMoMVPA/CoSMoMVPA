function test_suite = test_spherical_neighborhood
    initTestSuite;


function test_simple_neighborhood
    ds=cosmo_synthetic_dataset();
    nh1=cosmo_spherical_neighborhood(ds,'radius',0,'progress',false);
    assertEqual(nh1.a,ds.a);
    assertEqual(nh1.fa.i,ds.fa.i);
    assertEqual(nh1.fa.j,ds.fa.j);
    assertEqual(nh1.fa.k,ds.fa.k);
    assertEqual(nh1.fa.nvoxels,ones(1,6));
    assertEqual(nh1.fa.radius,zeros(1,6));
    assertEqual(nh1.fa.center_ids,1:6);
    assertEqual(nh1.neighbors,mat2cell((1:6)',ones(6,1),1));




    nh2=cosmo_spherical_neighborhood(ds,'radius',1.5,'progress',false);
    assertEqual(nh2.a,ds.a);
    assertEqual(nh2.fa.i,ds.fa.i);
    assertEqual(nh2.fa.j,ds.fa.j);
    assertEqual(nh2.fa.k,ds.fa.k);
    assertEqual(nh2.fa.nvoxels,[4 6 4 4 6 4]);
    assertEqual(nh2.fa.radius,ones(1,6)*1.5);
    assertEqual(nh2.fa.center_ids,1:6);
    assertEqual(nh2.neighbors,{ [ 1 4 2 5 ];...
                                 [ 2 1 5 3 4 6 ];...
                                 [ 3 2 6 5 ];...
                                 [ 4 1 5 2 ];...
                                 [ 5 4 2 6 1 3 ];...
                                 [ 6 5 3 2 ] });

    nh3=cosmo_spherical_neighborhood(ds,'count',4,'progress',false);
    assertEqual(nh3.a,ds.a);
    assertEqual(nh3.fa.i,ds.fa.i);
    assertEqual(nh3.fa.j,ds.fa.j);
    assertEqual(nh3.fa.k,ds.fa.k);
    assertEqual(nh3.fa.nvoxels,[4 4 4 4 4 4]);
    assertElementsAlmostEqual(nh3.fa.radius,...
                                [sqrt(2) 1 sqrt(2) sqrt(2) 1 sqrt(2)],...
                                'relative',1e-3);
    assertEqual(nh3.fa.center_ids,1:6);
    assertEqual(nh3.neighbors,{ [ 1 4 2 5 ];...
                                 [ 2 1 5 3 ];...
                                 [ 3 2 6 5 ];...
                                 [ 4 1 5 2 ];...
                                 [ 5 4 2 6 ];...
                                 [ 6 5 3 2 ] });

function test_exceptions
    ds=cosmo_synthetic_dataset();
    aet=@(x)assertExceptionThrown(@()...
                cosmo_spherical_neighborhood(x{:}),'');
    aet({ds});
    aet({ds,'foo'});
    aet({ds,'foo',1});
    aet({ds,'radius',[1 2]});
    aet({ds,'count',[1 2]});
    aet({ds,'radius',-1});
    aet({ds,'count',-1});
    aet({ds,'radius',1,'count',1});
    aet({ds,'count',7});
    aet({'foo','count',7});

function test_sparse_dataset
    nfeatures_test=3;

    ds=cosmo_synthetic_dataset('size','big');
    nf=size(ds.samples,2);
    rp=randperm(nf);
    ids=repmat(rp(1:round(nf*.4)),1,2);
    ds=cosmo_slice(ds,ids,2);


    nh4=cosmo_spherical_neighborhood(ds,'radius',3.05,'progress',false);
    assertEqual(nh4.a,ds.a);
    assertEqual(nh4.fa.i,ds.fa.i);
    assertEqual(nh4.fa.j,ds.fa.j);
    assertEqual(nh4.fa.k,ds.fa.k);

    rp=randperm(size(ds.samples,2));
    center_ids=rp(1:nfeatures_test);

    ijk=[ds.fa.i; ds.fa.j; ds.fa.k];
    for center_id=center_ids
        ijk_center=ijk(:,center_id);
        delta=sum(bsxfun(@minus,ijk_center,ijk).^2,1).^.5;
        nbr_ids=find(delta<=3.05);
        assertEqual(nbr_ids,sort(nh4.neighbors{center_id}));
    end







