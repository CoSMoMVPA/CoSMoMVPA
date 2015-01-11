function test_suite = test_searchlight
    initTestSuite;


function test_searchlight_

    ds=generate_test_dataset();

    measure=@(x,a) cosmo_structjoin('samples',size(x.samples,2));
    nh=cosmo_spherical_neighborhood(ds,'radius',3,'progress',0);

    m=cosmo_searchlight(ds,nh,measure,'progress',false);

    assertVectorsAlmostEqual(histc(m.samples,[38 46 47 100 123]),...
                            [ 24 24 558 352 35])

    nh2=cosmo_spherical_neighborhood(ds,'count',18,'progress',0);
    m=cosmo_searchlight(ds,nh2,measure,'progress',0);
    assertVectorsAlmostEqual(histc(m.samples,16:19),...
                            [24 76 406 495]);

    ds_small=cosmo_slice(ds,mod(ds.fa.i,3)==0,2);
    nh3=cosmo_spherical_neighborhood(ds_small,'count',18,'progress',0);
    m=cosmo_searchlight(ds_small,nh3,measure,'progress',0);
    assertVectorsAlmostEqual(histc(m.samples,16:19),[4 4 80 198]);
    assertVectorsAlmostEqual(m.samples([100 201]),[19 19]);



    % bit of a smoke test
    measure=@cosmo_correlation_measure;

    nh4=cosmo_spherical_neighborhood(ds,'radius',3,...
                                cosmo_structjoin('progress',0));
    m=cosmo_searchlight(ds, nh4, measure,...
                            'center_ids',[100 201],'progress',0);

    assertVectorsAlmostEqual(m.samples, [0.0075    0.1088]...
                                        ,'relative',.001);

