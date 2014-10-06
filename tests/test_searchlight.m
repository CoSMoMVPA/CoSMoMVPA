function test_suite = test_searchlight
    initTestSuite;


function test_searchlight_

    ds=generate_test_dataset();
    measure=@(x,a) cosmo_structjoin('samples',size(x.samples,2));
    m=cosmo_searchlight(ds, measure,'radius',3,'progress',0);
    assertVectorsAlmostEqual(histc(m.samples,[38 46 47 100 123]),...
                            [ 24 24 558 352 35])


    m=cosmo_searchlight(ds, measure,'radius',-18,'progress',0);
    assertVectorsAlmostEqual(histc(m.samples,[18 19 20 23 26]),...
                            [398 495 8 24 76]);

    d=cosmo_slice(ds,mod(ds.fa.i,3)==0,2);
    m=cosmo_searchlight(d, measure,'radius',-18,'progress',0);
    assertVectorsAlmostEqual(histc(m.samples,[18 19 21]),[80 56 150]);
    assertVectorsAlmostEqual(m.samples([100 201]),[21 18]);



    % bit of a smoke test
    measure=@cosmo_correlation_measure;

    nbrhood=cosmo_spherical_neighborhood(ds,3,cosmo_structjoin('progress',0));
    m=cosmo_searchlight(ds, measure,'nbrhood',nbrhood,...
                            'center_ids',[100 201],'progress',0);

    assertVectorsAlmostEqual(m.samples, [0.0075    0.1088]...
                                        ,'relative',.001);
