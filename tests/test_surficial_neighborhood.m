function test_suite = test_surficial_neighborhood
% tests for cosmo_surficial_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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
    assertFalse(isfield(nh1.a,'vol'));
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

    vertices2=[NaN NaN NaN; vertices;NaN NaN NaN];
    faces2=[faces+1; 1 1 8];
    args={{vertices2,faces2},'count',4,opt};
    nh2=cosmo_surficial_neighborhood(ds,args{:});

    assertEqual(nh2.neighbors,{ zeros(1,0)
                                 [ 2 3 5 6 ]
                                 [ 3 2 4 6 ]
                                 [ 4 3 6 2 ]
                                 [ 5 2 6 3 ]
                                 [ 6 3 5 4 ] });

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
    vertices=[-2 0 2 -2 0 2;...
                -1 -1 -1 1 1 1;...
                -1 -1 -1 -1 -1 -1]';
    faces= [ 3 2 3 2;...
                2 1 5 4;...
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
    assertFalse(isfield(nh3.a,'vol'));

    % TODO
    % check_partial_neighborhood(ds,nh3,args3);
    % check_partial_neighborhood(ds,nh3,args3);

function test_surficial_neighborhood_exceptions
    if cosmo_skip_test_if_no_external('surfing')
        return
    end
    ds=cosmo_synthetic_dataset('type','surface');%,'size','normal');
    [vertices,faces]=get_synthetic_surface();

    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_surficial_neighborhood(varargin{:},...
                                        'progress',false),'');
    aet(ds,{vertices,faces});

    % need surfaces
    aet(ds,{},'radius',2);

    % center_ids not supported for surface dataset
    aet(ds,{vertices,faces},'radius',2,'center_ids',1);

    % cannot have duplicate feature ids
    ds_double=cosmo_stack({ds,ds},2);
    ds_double.a.fdim.values{1}=[1:6,1:6];
    aet(ds_double,{vertices,faces},'radius',2);

    % outside range
    ds_double.a.fdim.values{1}=[1:5,1:5];
    aet(ds_double,{vertices,faces},'radius',2);

    % cannot have fmri and surface dataset combined
    ds2=cosmo_synthetic_dataset();
    ds2.a.fdim.values{end+1}=ds.a.fdim.values{1};
    ds2.a.fdim.labels{end+1}=ds.a.fdim.labels{1};
    ds2.fa.node_indices=ds.fa.node_indices;
    aet(ds2,{vertices,faces},'radius',2);

    % cannot have MEEG dataset
    ds_meeg=cosmo_synthetic_dataset('type','meeg');
    aet(ds_meeg,{vertices,faces},'radius',2);

    % need positive scalar radius
    aet(ds,{vertices,faces},'radius',-1);
    aet(ds,{vertices,faces},'radius',eye(2));


function check_partial_neighborhood(ds,nh,args)
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
                around_nodes=surfing_circleROI(vertices',faces',...
                            sel_center_node,metric_arg,metric,n2f);
        end

        sel_around_nodes=nodes_ds_sel(nb_sel{k});

        if isempty(sel_around_nodes)
            assertTrue(isempty(around_nodes));
        else
            assertEqual(unique(sel_around_nodes),...
                        setdiff(around_nodes, nodes_removed))
        end
    end


function test_surface_subsampling
    if cosmo_skip_test_if_no_external('surfing')
        return;
    end
    vertices=[0 -1 -2 -1  1  2  1  3  4  3;
          0 -2  0  2  2  0 -2  2  0 -2;
          0  0  0  0  0  0  0  0  0  0]';

    faces=[1 1 1 1 1 1 5 8 6  6;
           2 3 4 5 6 7 8 9 9 10;
           3 4 5 6 7 2 6 6 10 7]';

    % make custom volume
    ds=cosmo_synthetic_dataset('size','small');
    cp=cosmo_cartprod({1:7,1:3})';
    ds.fa.i=cp(1,:);
    ds.fa.j=cp(2,:);
    ds.fa.k=ds.fa.i*0+1;

    ds.a.fdim.values={1:7;1:3;1};
    ds.samples=zeros(numel(ds.sa.targets),numel(ds.fa.i));
    ds.a.vol.dim=cellfun(@numel,ds.a.fdim.values)';
    ds.a.vol.mat(2,4)=-4;
    ds.a.vol.mat(3,4)=-1;
    ds.a.vol.mat(1,1)=1;
    ds.a.vol.mat(2,2)=2;
    ds.a.vol.mat(3,3)=1;

    surfs={vertices,faces,[-4 5]};

    opt=struct();
    opt.progress=false;
    opt.radius=3;
    opt.metric='euclidean';
    nh=cosmo_surficial_neighborhood(ds,surfs,opt);

    assertEqual(nh.neighbors,{ [ 2 4 8 10 12 16 18 ]
                             [ 2 4 8 10 ]
                             [ 2 8 10 16 ]
                             [ 8 10 16 18 ]
                             [ 10 12 16 18 20 ]
                             [ 4 6 10 12 14 18 20 ]
                             [ 2 4 6 10 12 ]
                             [ 12 14 18 20 ]
                             [ 6 12 14 20 ]
                             [ 4 6 12 14 ] });
    assertEqual(nh.origin.fa,ds.fa);
    assertEqual(nh.origin.a,ds.a);

    % test subsampling
    subsample=2;
    surfs={vertices,faces,[-4 5],subsample};
    nh2=cosmo_surficial_neighborhood(ds,surfs,opt);
    assertEqual(nh2.neighbors,{ [ 2 4 8 10 ]
                                 [ 2 8 10 16 ]
                                 [ 8 10 16 18 ]
                                 [ 10 12 16 18 20 ]
                                 [ 2 4 6 10 12 ]
                                 [ 12 14 18 20 ]
                                 [ 6 12 14 20 ]
                                 [ 4 6 12 14 ] });

    assertEqual(nh2.origin.fa,ds.fa);
    assertEqual(nh2.origin.a,ds.a);

    % subsampling with pial surface
    pial=bsxfun(@plus,vertices,[0 0 1]);
    white=bsxfun(@plus,vertices,[0 0 -1]);
    [vo,fo]=surfing_subsample_surface(vertices,faces,2,.2,0);
    surfs={pial,white,faces,vo,fo};
    nh3=cosmo_surficial_neighborhood(ds,surfs,opt);
    assertEqual(nh2,nh3);

    % check center ids options
    slice_ids=[5 3 2];
    nh4=cosmo_surficial_neighborhood(ds,surfs,opt,'center_ids',slice_ids);
    nh4_sl=struct();
    nh4_sl.neighbors=nh3.neighbors(slice_ids);
    nh4_sl.fa=cosmo_slice(nh3.fa,slice_ids,2,'struct');
    nh4_sl.a=nh3.a;

    assertEqual(nh4.a.fdim.values{1}(nh4.fa.node_indices),...
                    nh4_sl.a.fdim.values{1}(nh4_sl.fa.node_indices));
    assertEqual(nh4.neighbors,nh4_sl.neighbors);


    % try with file names
    fn_pial=cosmo_make_temp_filename('pial','.asc');
    fn_white=cosmo_make_temp_filename('white','.asc');
    fn_tiny=cosmo_make_temp_filename('tiny','.asc');

    cleaner1=onCleanup(@()delete(fn_pial));
    cleaner2=onCleanup(@()delete(fn_white));
    cleaner3=onCleanup(@()delete(fn_tiny));

    surfing_write(fn_pial, pial, faces);
    surfing_write(fn_white, white, faces);
    surfing_write(fn_tiny, vo, fo);

    surfs={fn_pial,fn_white,fn_tiny};
    nh5=cosmo_surficial_neighborhood(ds,surfs,opt);
    assertEqual(nh2,nh5);

    % should work with alternative voldef
    ds_bad_vol=ds;
    ds_bad_vol.a.vol.mat(:)=NaN;
    ds_bad_vol.a.vol.dim(:)=NaN;
    nh6=cosmo_surficial_neighborhood(ds_bad_vol,surfs,opt,...
                                            'vol_def',ds.a.vol);
    nh6.origin.a.vol=ds.a.vol;
    assertEqual(nh5,nh6);

    % check exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_surficial_neighborhood(varargin{:}),'');

    surfs={fn_pial,fn_pial,fn_tiny};
    aet(ds,surfs,opt);

    white_bad=white;
    white_bad=white_bad(2:end,:);
    aet(ds,{pial,white_bad,faces},opt);

    % missing faces for output surface
    aet(ds,{fn_pial,fn_white,vo},opt);


    % face mismatch
    faces_bad=faces;
    faces_bad=faces_bad(end:-1:1,:);

    surfing_write(fn_white, white, faces_bad);
    aet(ds,{fn_pial,fn_white},opt);



    % too many surf arguments
    aet(ds,{fn_pial,fn_white,fn_tiny,fn_tiny},opt);
    aet(ds,{pial,white,faces,pial,white,white},opt);
    aet(ds,{pial,white,faces,fn_pial,white},opt);

    % surfs are not a cell
    aet(ds,struct,opt);
    aet(ds,{pial,white,{}});



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
