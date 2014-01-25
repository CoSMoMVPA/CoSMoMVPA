function test_suite = test_searchlight
    initTestSuite;


function test_searchlight_

    measure=@(x,a) cosmo_structjoin('samples',size(x.samples,2));
    m=cosmo_searchlight(ds, measure,'radius',3);
    assertVectorsAlmostEqual(histc(m.samples,[38 46 47 100 123]),...
                            [ 24 24 558 352 35])


    % bit of a smoke test
    measure=@cosmo_correlation_measure;

    nbrhood=cosmo_spherical_voxel_selection(ds,3);
    m=cosmo_searchlight(ds, measure,'nbrhood',nbrhood,'center_ids',[100 201]);

    assertVectorsAlmostEqual(m.samples,[0.0014 0.0204],'relative',.001);
