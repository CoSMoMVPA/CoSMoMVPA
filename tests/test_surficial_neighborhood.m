function test_suite = test_surficial_neighborhood
    initTestSuite;

function test_surficial_neighborhood_surface_dijkstra_and_direct
    if cosmo_skip_test_if_no_external('surfing')
        return;
    end
    warning_state=warning();
    warning_resetter=onCleanup(@()warning(warning_state));
    warning('off');

    opt=struct();
    opt.progress=false;

    ds=cosmo_synthetic_dataset('type','surface');%,'size','normal');

    vertices=[0 0 0 1 1 1;
                1 2 3 1 2 3;
                0 0 0 0 0 0]';
    faces= [ 3 2 3 2
                2 1 5 4
                5 4 6 5 ]';



    nh2=cosmo_surficial_neighborhood(ds,{vertices,faces},'count',4,...
                                    'metric','dijkstra',opt);
    assert_equal_cell(nh2.neighbors,{ [ 1 2 4 3 ]
                                        [ 2 1 3 5 ]
                                        [ 3 2 6 5 ]
                                        [ 4 1 5 2 ]
                                        [ 5 2 4 6 ]
                                        [ 6 3 5 2 ] });

    assertEqual(nh2.fa.radius,[2 1 sqrt(2) sqrt(2) 1 2]);
    assertEqual(nh2.fa.node_indices,1:6);

    nh3=cosmo_surficial_neighborhood(ds,{vertices,faces},...
                                    'direct',true,opt);
    assert_equal_cell(nh3.neighbors,{ [ 2 4 ]
                                        [ 3 1 4 5 ]
                                        [ 2 5 6 ]
                                        [ 1 2 5 ]
                                        [ 3 6 2 4 ]
                                        [ 3 5 ] });
    assertElementsAlmostEqual(nh3.fa.radius,sqrt([1 2 2 2 2 1]));

function test_surficial_neighborhood_surface_geodesic
    if cosmo_skip_test_if_no_external('fast_marching') || ...
            cosmo_skip_test_if_no_external('surfing')
        return;
    end

    warning_state=warning();
    warning_resetter=onCleanup(@()warning(warning_state));
    warning('off');

    opt=struct();
    opt.progress=false;

    ds=cosmo_synthetic_dataset('type','surface');%,'size','normal');

    vertices=[0 0 0 1 1 1;
                1 2 3 1 2 3;
                0 0 0 0 0 0]';
    faces= [ 3 2 3 2
                2 1 5 4
                5 4 6 5 ]';

    nh=cosmo_surficial_neighborhood(ds,{vertices,faces},'count',4,opt);
    assert_equal_cell(nh.neighbors,{[ 1 2 4 5 ]
                                    [ 2 1 3 5 ]
                                    [ 3 2 6 5 ]
                                    [ 4 1 5 2 ]
                                    [ 5 2 4 6 ]
                                    [ 6 3 5 2 ] });
    assertEqual(nh.fa.node_indices,1:6);
    assertEqual(nh.fa.radius,[sqrt(.5)+1 1 sqrt(2) sqrt(2) 1 sqrt(.5)+1]);

function test_surficial_neighborhood_volume_geodesic
    if cosmo_skip_test_if_no_external('fast_marching') || ...
            cosmo_skip_test_if_no_external('surfing')
        return;
    end
    warning_state=warning();
    warning_resetter=onCleanup(@()warning(warning_state));
    warning('off');

    opt=struct();
    opt.progress=false;

    ds=cosmo_synthetic_dataset();
    vertices=[-2 0 2 -2 0 2;
                -1 -1 -1 1 1 1
                -1 -1 -1 -1 -1 -1]';
    faces= [ 3 2 3 2
                2 1 5 4
                5 4 6 5 ]';
    pial=vertices;
    pial(:,3)=pial(:,3)+1;
    white=vertices;
    white(:,3)=white(:,3)-1;
    nh1=cosmo_surficial_neighborhood(ds,{vertices,[-1 1],faces},...
    'count',4,opt);
    nh2=cosmo_surficial_neighborhood(ds,{pial,white,faces},...
    'count',4,opt);
    assert_equal_cell(nh1.neighbors,{[ 1 2 4 5 ]
                                        [ 1 2 3 5 ]
                                        [ 2 3 5 6 ]
                                        [ 4 1 5 2 ]
                                        [ 5 2 4 6 ]
                                        [ 6 3 5 2 ] });
    assertEqual(nh1.fa.node_indices,1:6);
    assertEqual(nh1,nh2);


function test_surficial_neighborhood_volume_dijkstra
    if cosmo_skip_test_if_no_external('surfing')
        return;
    end
    warning_state=warning();
    warning_resetter=onCleanup(@()warning(warning_state));
    warning('off');

    opt=struct();
    opt.progress=false;

    ds=cosmo_synthetic_dataset();
    vertices=[-2 0 2 -2 0 2;
                -1 -1 -1 1 1 1
                -1 -1 -1 -1 -1 -1]';
    faces= [ 3 2 3 2
                2 1 5 4
                5 4 6 5 ]';
    pial=vertices;
    pial(:,3)=pial(:,3)+1;
    white=vertices;
    white(:,3)=white(:,3)-1;

    nh3=cosmo_surficial_neighborhood(ds,{vertices,[-1 1],faces},...
    'metric','dijkstra','count',4,opt);
    nh4=cosmo_surficial_neighborhood(ds,{pial,white,faces},...
    'metric','dijkstra','count',4,opt);
    assert_equal_cell(nh3.neighbors,{ [ 1 2 4 3 ]
                                        [ 2 1 3 5 ]
                                        [ 3 2 6 5 ]
                                        [ 4 1 5 2 ]
                                        [ 5 2 4 6 ]
                                        [ 6 3 5 2 ] });
    assertEqual(nh3.fa.node_indices,1:6);
    assert_equal_cell(nh4.neighbors,nh3.neighbors);

function test_surficial_neighborhood_exceptions
    if cosmo_skip_test_if_no_external('surfing')
        return
    end
    ds=cosmo_synthetic_dataset('type','surface');%,'size','normal');
    vertices=[0 0 0 1 1 1;
                1 2 3 1 2 3;
                0 0 0 0 0 0]';
    faces= [ 3 2 3 2
                2 1 5 4
                5 4 6 5 ]';
    aet=@(x)assertExceptionThrown(@()...
    cosmo_surficial_neighborhood(x{:},'progress',false),'');
    aet({ds,{vertices,faces}});
    ds2=cosmo_stack({ds,ds},2);
    aet({ds2,{vertices,faces},'count',1});
    ds3=cosmo_slice(ds,1:4,2);
    aet({ds3,{vertices,faces},'count',2});
    ds3=cosmo_dim_prune(ds3);
    aet({ds3,{vertices,faces},'count',2});



function assert_equal_cell(x,y)
    % small helper
    assertEqual(size(x),size(y))
    for k=1:numel(x)
        xk=x{k};
        yk=y{k};
        assertEqual(sort(xk),sort(yk));
    end
