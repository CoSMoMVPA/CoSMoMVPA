function test_suite = test_surficial_neighborhood
    initTestSuite;

function test_surficial_neighborhood_surface_dijkstra
    if cosmo_skip_test_if_no_external('surfing')
        return;
    end
    warning_state=warning();
    warning_resetter=onCleanup(@()warning(warning_state));
    warning('off');

    opt=struct();
    opt.progress=false;

    ds=cosmo_synthetic_dataset('type','surface');

    [vertices,faces]=get_synthetic_surface();

    % dijkstra neighborhood fixed number of voxels
    args={{vertices,faces},'count',4,'metric','dijkstra',opt};
    nh1=cosmo_surficial_neighborhood(ds,args{:});
    assert_equal_cell(nh1.neighbors,{ [ 1 2 4 3 ]
                                        [ 2 1 3 5 ]
                                        [ 3 2 6 5 ]
                                        [ 4 1 5 2 ]
                                        [ 5 2 4 6 ]
                                        [ 6 3 5 2 ] });

    assertEqual(nh1.fa.radius,[2 1 sqrt(2) sqrt(2) 1 2]);
    assertEqual(nh1.fa.node_indices,1:6);

    args={{vertices,faces},'radius',2.5,'metric','dijkstra',opt};
    nh2=cosmo_surficial_neighborhood(ds,args{:});

    assert_equal_cell(nh2.neighbors,{[1 2 3 4 5];
                                     [1 2 3 4 5 6];
                                     [1 2 3 4 5 6];
                                     [1 2 3 4 5 6];
                                     [1 2 3 4 5 6];
                                     [2 3 4 5 6]; });
    assertEqual(nh2.fa.radius,[2,2,1+sqrt(2),1+sqrt(2),2,2]);
    assertEqual(nh2.fa.node_indices,1:6);
    check_partial_neighborhood(ds,nh2,args);

    args{1}{1}([2,6],:)=NaN;

    nh3=cosmo_surficial_neighborhood(ds,args{:});
    assert_equal_cell(nh3.neighbors,{[1 4 5];
                                     [];
                                     [3 4 5];
                                     [1 3 4 5];
                                     [1 3 4 5];
                                     []; });
    assertEqual(nh3.fa.radius,[2,NaN,1+sqrt(2),1+sqrt(2),2,NaN]);
    check_partial_neighborhood(ds,nh3,args);

    args{2}='count';
    args{3}=3;

    nh4=cosmo_surficial_neighborhood(ds,args{:});
    assert_equal_cell(nh4.neighbors,{[1 4 5];
                                     [];
                                     [3 5 4];
                                     [4 1 5];
                                     [5 4 3];
                                     []; });
    assertEqual(nh4.fa.radius,[2,NaN,1+sqrt(2),1,sqrt(2),NaN]);

    args{1}{1}=vertices;
    args{1}{1}([2,5],:)=NaN; % split in two surfaces
    args{3}=2;
    nh5=cosmo_surficial_neighborhood(ds,args{:});
    assert_equal_cell(nh5.neighbors,{[1 4];
                                     [];
                                     [3 6];
                                     [4 1];
                                     [];
                                     [6 3]; });
    assertEqual(nh5.fa.radius,[1,NaN,1,1,NaN,1]);

    % throw error when too many nodes asked for
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_surficial_neighborhood(varargin{:}),'');
    args{2}='count';
    args{3}=3;

    aet(ds,args{:})



function test_surficial_neighborhood_surface_direct
    if cosmo_skip_test_if_no_external('surfing')
        return;
    end
    warning_state=warning();
    warning_resetter=onCleanup(@()warning(warning_state));
    warning('off');

    opt=struct();
    opt.progress=false;

    ds=cosmo_synthetic_dataset('type','surface');

    [vertices,faces]=get_synthetic_surface();

    % direct neighborhood
    args={{vertices,faces},'direct',true,opt};
    nh3=cosmo_surficial_neighborhood(ds,args{:});
    assert_equal_cell(nh3.neighbors,{ [ 1 2 4 ]
                                        [ 2 3 1 4 5 ]
                                        [ 3 2 5 6 ]
                                        [ 4 1 2 5 ]
                                        [ 5 3 6 2 4 ]
                                        [ 6 3 5 ] });
    assertElementsAlmostEqual(nh3.fa.radius,sqrt([1 2 2 2 2 1]));
    check_partial_neighborhood(ds,nh3,args);

    args{1}{1}([2 5],:)=NaN;
    nh4=cosmo_surficial_neighborhood(ds,args{:});
    assert_equal_cell(nh4.neighbors,{ [ 1 4 ]
                                        []
                                        [ 3 6 ]
                                        [ 1 4 ]
                                        []
                                        [6 3] });

    check_partial_neighborhood(ds,nh4,args);

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

    [vertices,faces]=get_synthetic_surface();

    args={{vertices,faces},'count',4,opt};
    nh=cosmo_surficial_neighborhood(ds,args{:});
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

    args3={{vertices,[-1 1],faces},'metric','dijkstra','count',4,opt};
    args4={{pial,white,faces},'metric','dijkstra','count',4,opt};
    nh3=cosmo_surficial_neighborhood(ds,args3{:});
    nh4=cosmo_surficial_neighborhood(ds,args4{:});
    assert_equal_cell(nh3.neighbors,{ [ 1 2 4 3 ]
                                        [ 2 1 3 5 ]
                                        [ 3 2 6 5 ]
                                        [ 4 1 5 2 ]
                                        [ 5 2 4 6 ]
                                        [ 6 3 5 2 ] });
    assertEqual(nh3.fa.node_indices,1:6);
    assert_equal_cell(nh4.neighbors,nh3.neighbors);

    % TODO
    % check_partial_neighborhood(ds,nh3,args3);
    % check_partial_neighborhood(ds,nh3,args3);

function test_surficial_neighborhood_exceptions
    if cosmo_skip_test_if_no_external('surfing')
        return
    end
    ds=cosmo_synthetic_dataset('type','surface');%,'size','normal');
    [vertices,faces]=get_synthetic_surface();

    aet=@(x)assertExceptionThrown(@()...
    cosmo_surficial_neighborhood(x{:},'progress',false),'');
    aet({ds,{vertices,faces}});


function check_partial_neighborhood(ds,nh,args)
    % TODO: enable this test

    % see if when have a partial dataset, the neighborbood reflects
    % that too

    nf=size(ds.samples,2);

    rp=randperm(nf);
    keep_count=round(nf*.7);
    keep_sel=rp(1:keep_count);
    keep_all=[keep_sel keep_sel keep_sel];

    ds_sel=cosmo_slice(ds,keep_all,2);

    fdim=ds_sel.a.fdim.values{1};
    rp_fdim=randperm(numel(fdim));
    ds_sel.a.fdim.values{1}=fdim(rp_fdim);

    nh_sel=cosmo_surficial_neighborhood(ds_sel,args{:});

    assertEqual(numel(nh_sel.neighbors), numel(keep_sel));

    assertEqual(nh_sel.a.fdim.labels,nh.a.fdim.labels);
    assertEqual(nh_sel.a.fdim.values{1},nh.a.fdim.values{1}(rp_fdim));
    assertEqual(numel(nh_sel.a.fdim.values),numel(nh.a.fdim.values));

    assertEqual(ds_sel.a,nh_sel.a);
    %assertEqual(sort(nh.a.fdim.values{1}(nh.fa.node_indices(keep_sel))),...
    %            sort(nh_sel.a.fdim.values{1}(nh_sel.fa.node_indices)));




    opt=cosmo_structjoin(args(2:end));


    if isfield(opt,'radius')
        metric=opt.metric;
        metric_arg=opt.radius;
    elseif isfield(opt,'count')
        metric=opt.metric;
        metric_arg=[10 opt.count];
    elseif isfield(opt,'direct')
        metric='direct';
        if opt.direct
            metric_arg=NaN;
        else
            metric_arg=0;
        end
    else
        assert(false);
    end



    faces=args{1}{2};
    n2f=surfing_invertmapping(faces);

    nodes_ds_sel=ds_sel.a.fdim.values{1}(ds_sel.fa.node_indices);
    nodes_ds=ds.a.fdim.values{1}(ds.fa.node_indices);

    nodes_nh_sel=nh_sel.a.fdim.values{1}(nh_sel.fa.node_indices);

    vertices=args{1}{1};


    nvertices=size(vertices,1);
    nodes_kept=cosmo_match(1:nvertices,nodes_ds_sel);
    vertices(~nodes_kept,:)=NaN;

    node_mask=all(isfinite(vertices),2);

    nodes_removed=setdiff(nodes_ds(:)',nodes_ds_sel(:)');
    assertEqual(setxor(nodes_removed,nodes_ds_sel),1:nf);

    nb_sel=nh_sel.neighbors;
    for k=1:numel(nh_sel.neighbors)
        sel_center_node=nodes_nh_sel(k);
        idx=find(nodes_ds==sel_center_node);
        assert(numel(idx)==1);
        center_node=nodes_ds(idx);

        assertEqual(sel_center_node, center_node);

        switch metric
            case 'direct'
                if node_mask(sel_center_node)
                    direct_neighbors=surfing_surface_nbrs(faces',...
                                                            vertices');
                    around_nodes=direct_neighbors(sel_center_node,:);
                    msk=cosmo_match(around_nodes, ...
                                            find(isfinite(vertices(:,1))));
                    % add node itself
                    around_nodes=[sel_center_node,...
                                    around_nodes(msk & around_nodes>0)];
                else
                    around_nodes=[];
                end
            otherwise
                around_nodes=surfing_circleROI(vertices',faces',sel_center_node,metric_arg,metric,n2f);
        end

        sel_around_nodes=nodes_ds_sel(nb_sel{k});

        if isempty(sel_around_nodes)
            assertTrue(isempty(around_nodes));
        else
            assertEqual(unique(sel_around_nodes),setdiff(around_nodes, nodes_removed))
        end
    end



function [vertices,faces]=get_synthetic_surface()
    % return the following surface (face indices in [brackets])
    %
    %  1-----2-----3
    %  |    /|    /|
    %  |[2]/ |[1]/ |
    %  |  /  |  /  |
    %  | /[4]| /[3]|
    %  |/    |/    |
    %  4-----5-----6

    vertices=[0 0 0 1 1 1;
                1 2 3 1 2 3;
                0 0 0 0 0 0]';
    faces= [ 3 2 3 2
                2 1 5 4
                5 4 6 5 ]';


function assert_equal_cell(x,y)
    % small helper
    assertEqual(size(x),size(y))
    for k=1:numel(x)
        xk=x{k};
        yk=y{k};
        if isempty(xk)
            assertTrue(isempty(yk));
        else
            assertEqual(sort(xk),sort(yk));
        end
    end
