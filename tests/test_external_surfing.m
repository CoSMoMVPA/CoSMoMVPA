function test_suite=test_external_surfing()
% regression tests for external "surfing" toolbox
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_surfing_subsample_surface()
    if cosmo_skip_test_if_no_external('surfing')
        return;
    end
    opt=struct();
    opt.progress=false;

    vertices=[0 -1 -2 -1  1  2  1  3  4  3;
              0 -2  0  2  2  0 -2  2  0 -2;
              0  0  0  0  0  0  0  0  0  0]';

    faces=[1 1 1 1 1 1 5 8 6  6;
           2 3 4 5 6 7 8 9 9 10;
           3 4 5 6 7 2 6 6 10 7]';


    [v_sub,f_sub]=surfing_subsample_surface(vertices,faces,1,.2,false);

    assertEqual(v_sub',[ -1 -2 -1 1 2 1 3 4 3
                         -2 0 2 2 0 -2 2 0 -2
                          0 0 0 0 0 0 0 0 0 ]);
    assertEqual(f_sub',[ 1 1 1 1 4 5 7 5
                         2 3 4 5 7 9 8 8
                         3 4 5 6 5 6 5 9 ]);

    [v_sub2,f_sub2]=surfing_subsample_surface(v_sub,f_sub,1,.2,false);
    assertEqual(v_sub2',[ -1 -2 -1 1 1 3 4 3
                          -2 0 2 2 -2 2 0 -2
                           0 0 0 0 0 0 0 0 ]);

    assertEqual(f_sub2',[ 1 1 1 4 6 4
                          2 3 4 8 7 7
                          3 4 5 5 4 8 ]);

    [v_sub2_alt,f_sub2_alt]=surfing_subsample_surface(vertices,faces,...
                                                        2,.2,false);
    assertEqual(v_sub2_alt,v_sub2);
    assertEqual(f_sub2_alt,f_sub2);


function test_surfing_generate_planar_surface()
    if cosmo_skip_test_if_no_external('surfing')
        return;
    end

    if isempty(which('surfing_generate_planar_surface'))
        % older versions of surfing
        cosmo_notify_test_skipped(['surfing_generate_planar_surface '...
                                    'is not available']);
        return;
    end

    nx=round(rand()*5)+5;
    ny=round(rand()*5)+5;

    origin=rand(3,1)*10;
    x1=rand(3,1)*10;
    y1=rand(3,1)*10;

    [v1,f1]=generate_planar_surface(nx,ny,origin,x1,y1);
    [v2,f2]=surfing_generate_planar_surface(nx,ny,origin,x1,y1);
    assertElementsAlmostEqual(v1,v2);
    assertElementsAlmostEqual(f1,f2);

    % test default options
    [v1,f1]=generate_planar_surface(nx,ny,[0,0,0],[1,0,0],[0,1,0]);
    [v2,f2]=surfing_generate_planar_surface(nx,ny);
    assertElementsAlmostEqual(v1,v2);
    assertElementsAlmostEqual(f1,f2);


function test_surfing_voxel_selection_dijkstra()
    helper_test_surfing_voxel_selection('dijkstra')

function test_surfing_voxel_selection_euclidean()
    helper_test_surfing_voxel_selection('euclidean')


function helper_test_surfing_voxel_selection(metric)
    if cosmo_skip_test_if_no_external('surfing')
        return;
    end
    warning_state=warning();
    warning_resetter=onCleanup(@()warning(warning_state));
    warning('off');

    nx=round(rand()*5)+5;
    ny=round(rand()*5)+5;

    % surface with some nodes outside the volume
    [v,f]=generate_planar_surface(nx,ny,[-4,-4,0],[1,0,0],[0,1,0]);
    thickness=rand()*2+2;
    pial=bsxfun(@plus,v,[0,0,-thickness])';
    white=bsxfun(@plus,v,[0,0,thickness])';


    ds=cosmo_synthetic_dataset('size','big');
    ds_xyz=cosmo_vol_coordinates(ds);
    voldef=ds.a.vol;
    half_vox_size=voldef.mat(1);
    thickness_margin=thickness+half_vox_size;

    radius=rand()*4+2;
    args={pial,white,f',radius,voldef,[],[],metric,0};
    n2v=surfing_voxelselection(args{:});

    switch metric
        case 'dijkstra'
            extra_distance=0;

        case 'euclidean'
            extra_distance=0;

        otherwise
            error('illegal distance ''%s''', metric);
    end

    nv=size(v,1);
    rp=randperm(nv);

    for k=1:nv/2
        node_id=rp(k);
        node_xyz=v(node_id,:);

        is_inside=~isequal(cosmo_vol_coordinates(ds,node_xyz'),0);
        voxel_ids=n2v{node_id};
        has_voxels=~isempty(voxel_ids);

        assertEqual(is_inside,has_voxels);
        if is_inside
            voxels_xyz=ds_xyz(:,n2v{node_id})';
            voxels_z=voxels_xyz(:,3);

            % check z coordinates
            assert(all(-thickness_margin <= voxels_z & ...
                        voxels_z <= thickness_margin))

            distances=euclidean_distance(ds_xyz',node_xyz,1:3);

            node_distances=distances(n2v{node_id});
            assert(all(node_distances<=radius+thickness_margin));

            % check voxels not selected
            nfeatures=size(ds_xyz,2);
            candidates=true(nfeatures,1);
            candidates(ds_xyz(1,:)<=min(v(:,1)))=false;
            candidates(ds_xyz(2,:)<=min(v(:,2)))=false;
            candidates(ds_xyz(3,:)<=-(thickness+half_vox_size))=false;
            candidates(ds_xyz(1,:)>=max(v(:,1)))=false;
            candidates(ds_xyz(2,:)>=max(v(:,2)))=false;
            candidates(ds_xyz(3,:)>=thickness+half_vox_size)=false;
            candidates(n2v{node_id})=false;

            if any(candidates)
                min_outside=min(distances(candidates));
                assert(min_outside>radius-half_vox_size);
            end
        end

        % check individual call for this node id
        args_single_node=args;
        args_single_node{6}=node_id;
        n2v_single_node=surfing_voxelselection(args_single_node{:});
        assertEqual(n2v_single_node,n2v(node_id));
    end

function d=euclidean_distance(p,q,dim)
    d=sqrt(sum(bsxfun(@minus,p(:,dim),q(:,dim)).^2,2));



function [vertices,faces]=generate_planar_surface(nx, ny, origin, x1, y1)

    vertices=zeros(nx*ny,3);
    faces=zeros(2*(nx-1)*(ny-1),3);

    for i=1:nx
        for j=1:ny
            vpos=(i-1)*ny+j;
            vertices(vpos,:)=origin+(i-1)*x1+(j-1)*y1;
            if i<nx && j<ny
                p=vpos;
                q=vpos+1;
                r=vpos+ny;
                s=vpos+ny+1;

                fpos=((i-1)*(ny-1)+j)*2-1;
                faces(fpos,:)=[p,q,r];
                faces(fpos+1,:)=[s,r,q];
            end
        end
    end

