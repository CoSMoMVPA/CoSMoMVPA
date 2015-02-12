function test_suite = test_chunkize
    initTestSuite;


function test_chunkize_basis
    ds=cosmo_synthetic_dataset('type','timelock','nreps',8);
    ds.sa.chunks=reshape(repmat((1:8),6,1),[],1);
    ds=cosmo_slice(ds,randperm(48));

    chunks=cosmo_chunkize(ds,8);
    assertEqual(chunks,ds.sa.chunks);

    for j=1:2:7
        chunks=cosmo_chunkize(ds,j);
        eq_chunks=bsxfun(@eq,chunks,chunks');
        eq_ds=bsxfun(@eq,ds.sa.chunks,ds.sa.chunks');

        m=eq_ds & ~eq_chunks;
        assert(~any(m(:)));
    end

    assertExceptionThrown(@()cosmo_chunkize(ds,9),'');
    ds=rmfield(ds.sa,'chunks');
    assertExceptionThrown(@()cosmo_chunkize(ds,2),'');


function test_chunkize_imbalance()
    ds=struct();
    ds.samples=(1:5)';
    assertExceptionThrown(@()cosmo_chunkize(ds,2),'');
    ds.sa.chunks=2+[1 1 2 2 2]';
    assertExceptionThrown(@()cosmo_chunkize(ds,2),'');
    ds.sa.targets=10+[1 2 1 2 2]';
    assertExceptionThrown(@()cosmo_chunkize(ds,3),'');
    res=cosmo_chunkize(ds,2);

    assertEqual(res,[1 1 2 2 2]');
    ds2=cosmo_stack({ds,ds});
    res2=cosmo_chunkize(ds2,2);
    assertEqual(res2,[1 1 2 2 2 1 1 2 2 2]');

function test_all_unique_chunks()
    ds=struct();
    ds.samples=(1:5)';
    ds.sa.targets=2+[1 1 2 2 2]';
    ds.sa.chunks=10+[1 2 3 4 5]';

    res=cosmo_chunkize(ds,2);
    assertEqual(res,[1 2 1 2 1]');

    res=cosmo_chunkize(ds,5);
    assertEqual(res,[1 2 3 4 5]');


    assertExceptionThrown(@()cosmo_chunkize(ds,6),'');











