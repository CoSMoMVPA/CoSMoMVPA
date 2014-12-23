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





