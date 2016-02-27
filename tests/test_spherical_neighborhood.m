function test_suite = test_spherical_neighborhood
% tests for cosmo_spherical_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_simple_neighborhood
    ds=cosmo_synthetic_dataset();
    nh1=cosmo_spherical_neighborhood(ds,'radius',0,'progress',false);

    mp=cosmo_align({ds.fa.i, ds.fa.j, ds.fa.k},...
                        {nh1.fa.i, nh1.fa.j, nh1.fa.k});
    ds_al=cosmo_slice(ds,mp,2);
    assertEqual(nh1.a,ds.a);
    assertEqual(nh1.fa.i,ds_al.fa.i);
    assertEqual(nh1.fa.j,ds_al.fa.j);
    assertEqual(nh1.fa.k,ds_al.fa.k);
    assertEqual(nh1.fa.nvoxels,ones(1,6));
    assertEqual(nh1.fa.radius,zeros(1,6));
    assertEqual(nh1.fa.center_ids,mp);
    assertEqual(nh1.neighbors,num2cell(mp'));

    assertEqual(nh1.origin.fa,ds_al.fa);
    assertEqual(nh1.origin.a.fdim,ds_al.a.fdim);


    nh2=cosmo_spherical_neighborhood(ds,'radius',1.5,'progress',false);
    mp=cosmo_align({ds.fa.i, ds.fa.j, ds.fa.k},...
                        {nh1.fa.i, nh1.fa.j, nh1.fa.k});
    ds_al=cosmo_slice(ds,mp,2);
    assertEqual(nh2.a,ds.a);
    assertEqual(nh2.fa.i,ds_al.fa.i);
    assertEqual(nh2.fa.j,ds_al.fa.j);
    assertEqual(nh2.fa.k,ds_al.fa.k);
    nvoxels=[4 6 4 4 6 4];
    assertEqual(nh2.fa.nvoxels,nvoxels(mp));
    assertEqual(nh2.fa.radius,ones(1,6)*1.5);
    assertEqual(nh2.fa.center_ids,mp);
    assertEqual(numel(nh2.neighbors),6);
    nh={ [ 1 4 2 5 ];...
         [ 2 1 5 3 4 6 ];...
         [ 3 2 6 5 ];...
         [ 4 1 5 2 ];...
         [ 5 4 2 6 1 3 ];...
         [ 6 5 3 2 ] };
    for k=1:6
        assertEqual(nh2.neighbors{k},nh{mp(k)});
    end


    nh3=cosmo_spherical_neighborhood(ds,'count',4,'progress',false);
    mp=cosmo_align({ds.fa.i, ds.fa.j, ds.fa.k},...
                        {nh1.fa.i, nh1.fa.j, nh1.fa.k});
    ds_al=cosmo_slice(ds,mp,2);
    assertEqual(nh3.a,ds.a);
    assertEqual(nh3.fa.i,ds_al.fa.i);
    assertEqual(nh3.fa.j,ds_al.fa.j);
    assertEqual(nh3.fa.k,ds_al.fa.k);
    assertEqual(nh3.fa.nvoxels,[4 4 4 4 4 4]);
    radii=[sqrt(2) 1 sqrt(2) sqrt(2) 1 sqrt(2)];
    assertElementsAlmostEqual(nh3.fa.radius,...
                                radii(mp),...
                                'relative',1e-3);
    assertEqual(nh3.fa.center_ids,mp);
    assertEqual(numel(nh3.neighbors),6);
    nh={ [ 1 4 2 5 ];...
         [ 2 1 5 3 ];...
         [ 3 2 6 5 ];...
         [ 4 1 5 2 ];...
         [ 5 4 2 6 ];...
         [ 6 5 3 2 ] };
    for k=1:6
        assertEqual(nh3.neighbors{k},nh{mp(k)});
    end

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
    nf_full=round(nf*.4);
    ids=rp(1:nf_full);

    ds_sel=cosmo_slice(ds,ids,2);

    ids_full=repmat(ids,1,2);
    ds_full=cosmo_slice(ds,ids_full,2);

    radius=2+rand();
    nh4=cosmo_spherical_neighborhood(ds_full,'radius',radius,...
                                    'progress',false);
    assertEqual(numel(nh4.neighbors),numel(ids));
    mp=cosmo_align({ds_sel.fa.i, ds_sel.fa.j, ds_sel.fa.k},...
                        {nh4.fa.i, nh4.fa.j, nh4.fa.k});
    ds_al=cosmo_slice(ds_sel,mp,2);

    assertEqual(nh4.a,ds.a);
    assertEqual(nh4.fa.i,ds_al.fa.i);
    assertEqual(nh4.fa.j,ds_al.fa.j);
    assertEqual(nh4.fa.k,ds_al.fa.k);
    assertEqual(nh4.fa.center_ids,mp);

    rp=randperm(size(ds_al.samples,2));
    center_ids=rp(1:nfeatures_test);

    ijk=[ds_al.fa.i; ds_al.fa.j; ds_al.fa.k];
    ijk_full=[ds_full.fa.i; ds_full.fa.j; ds_full.fa.k];
    for center_id=center_ids
        ijk_center=ijk(:,center_id);
        delta=sum(bsxfun(@minus,ijk_center,ijk_full).^2,1).^.5;
        nbr_ids=find(delta<=radius);
        assertEqual(nbr_ids,sort(nh4.neighbors{center_id}));
    end


function test_with_freq_dimension_dataset
    ds=cosmo_synthetic_dataset('size','big');
    nfeatures=size(ds.samples,2);

    freqs=[2 4 6];
    nfreqs=numel(freqs);
    ds_cell=cell(nfreqs,1);
    for k=1:nfreqs
        ds_freq=ds;
        ds_freq.a.fdim.labels=[{'freq'};ds_freq.a.fdim.labels];
        ds_freq.a.fdim.values=[{freqs};ds_freq.a.fdim.values];
        ds_freq.fa.freq=ones(1,nfeatures)*k;
        ds_cell{k}=ds_freq;
    end

    ds_full=cosmo_stack(ds_cell,2);
    rp=randperm(nfeatures*nfreqs);
    id_full=rp(1:((nfreqs-1)*nfeatures));
    ds_full=cosmo_slice(ds_full,id_full,2);

    ijk_full=[ds_full.fa.i; ds_full.fa.j; ds_full.fa.k];
    [ijk_idxs,ijk_unq]=cosmo_index_unique(ijk_full');
    ijk_idx=cellfun(@(x)x(1),ijk_idxs);
    ds_al=cosmo_slice(ds_full,ijk_idx,2);

    radius=5+rand()*3;
    nh=cosmo_spherical_neighborhood(ds_full,'radius',radius,...
                                            'progress',false);

    assertEqual(nh.fa.i,ds_al.fa.i);
    assertEqual(nh.fa.j,ds_al.fa.j);
    assertEqual(nh.fa.k,ds_al.fa.k);
    assertEqual(nh.a.fdim.labels,ds_full.a.fdim.labels(2:4));
    assertEqual(nh.a.fdim.values,ds_full.a.fdim.values(2:4));
    assertEqual(numel(nh.neighbors),numel(ijk_idxs));

    ijk_full=[ds_full.fa.i; ds_full.fa.j; ds_full.fa.k];
    ijk_al=[ds_al.fa.i; ds_al.fa.j; ds_al.fa.k];

    % test match for euclidean distance
    rp=randperm(numel(ijk_idxs));
    rp=rp(1:10);
    for r=rp
        nbrs=nh.neighbors{r};

        ijk_center=ijk_al(:,r);
        delta=sum(bsxfun(@minus,ijk_center,ijk_full).^2,1).^.5;
        assertEqual(find(delta<=radius), sort(nbrs));
    end

    % test with transposed dimension values
    ds2_full=ds_full;
    ds2_full.a.fdim.values=cellfun(@transpose,...
                            ds2_full.a.fdim.values,...
                            'UniformOutput',false)';
    nh2=cosmo_spherical_neighborhood(ds2_full,'radius',radius,...
                                                'progress',false);

    nh2.origin.a.fdim.values=cellfun(@transpose,...
                             nh2.origin.a.fdim.values,...
                            'UniformOutput',false)';
    assertEqual(nh,nh2);
    assertFalse(isfield(nh.fa,'inside'));

function test_meeg_source_dataset
    ds=cosmo_synthetic_dataset('type','source','size','normal');
    nf=size(ds.samples,2);

    [unused,idxs]=sort(cosmo_rand(1,nf*4,'seed',1));
    rps=mod(idxs-1,nf)+1;
    id_full=rps(round(nf/2)+(1:(3*nf)));
    ds_full=cosmo_slice(ds,id_full,2);

    pos_full=ds_full.fa.pos;
    pos_idxs=cosmo_index_unique(pos_full');
    pos_idx=cellfun(@(x)x(1),pos_idxs);
    ds_unq=cosmo_slice(ds_full,pos_idx,2);

    radius=1.2+.2*rand();

    nh=cosmo_spherical_neighborhood(ds_full,'radius',radius,...
                                                'progress',false);
    mp=cosmo_align(ds_unq.fa.pos',nh.fa.pos');
    ds_al=cosmo_slice(ds_unq,mp,2);
    assertEqual(nh.fa.pos,ds_al.fa.pos);
    assertEqual(nh.a.fdim.labels{1},ds.a.fdim.labels{1});
    assertEqual(nh.a.fdim.values{1},ds.a.fdim.values{1});
    assertEqual(numel(nh.neighbors),numel(pos_idx));

    count=ceil(4/3*pi*(radius)^3 * .5);
    nh2=cosmo_spherical_neighborhood(ds_full,'count',count,...
                                                'progress',false);
    assertEqual(nh2.fa.pos,ds_al.fa.pos);
    assertEqual(nh2.a.fdim.labels{1},ds.a.fdim.labels{1});
    assertEqual(nh2.a.fdim.values{1},ds.a.fdim.values{1});
    assertEqual(numel(nh2.neighbors),numel(pos_idx));

    pos_al=ds_al.a.fdim.values{1}(:,ds_al.fa.pos);
    pos_full=nh.a.fdim.values{1}(:,ds_full.fa.pos);

    voxel_size=10;
    for r=1:numel(pos_idx)
        d=sum(bsxfun(@minus,pos_full,pos_al(:,r)).^2,1).^.5;
        idxs=find(d<=(radius*voxel_size));

        assertEqual(sort(nh.neighbors{r}),sort(idxs));
    end

    [p,q]=cosmo_overlap(nh.neighbors,nh2.neighbors);

    dp=diag(p);
    dq=diag(q);

    assertTrue(mean(dp)>.8);
    assertTrue(mean(dq)>.3);

function test_small_meeg_source_dataset_without_inside_field
    ds=cosmo_synthetic_dataset('type','source','size','small');
    voxel_size=10;
    idx=cosmo_index_unique(ds.fa.pos');
    n_pos=numel(idx);

    ds_pos=ds.a.fdim.values{1}(:,ds.fa.pos);

    for radius=0:.4:2;
        nh=cosmo_spherical_neighborhood(ds,...
                    'radius',radius,...
                    'progress',false);
        center_pos=nh.a.fdim.values{1}(:,nh.fa.pos);
        assertEqual(numel(nh.neighbors),n_pos);
        for k=1:n_pos
            sel_idx=nh.neighbors{k};

            delta=bsxfun(@minus,center_pos(:,k),...
                                 ds_pos);
            distance=sqrt(sum((delta/voxel_size).^2,1));

            expected_sel_idx=find(distance<=radius);

            assertEqual(sort(sel_idx(:)),sort(expected_sel_idx(:)));
        end
    end



function test_small_meeg_source_dataset_with_inside_field
    ds=cosmo_synthetic_dataset('type','source','size','small');
    voxel_size=10;
    nf=size(ds.samples,2);

    idx=cosmo_index_unique(ds.fa.pos');
    n_pos=numel(idx);

    for keep_ratio=.4:.3:1;
        keep=randperm(n_pos);
        n_keep=round(n_pos*keep_ratio);
        keep=keep(1:n_keep);

        ds.fa.inside=false(1,nf);
        for k=1:numel(keep)
            ds.fa.inside(idx{keep(k)})=true;
        end

        ds_pos=ds.a.fdim.values{1}(:,ds.fa.pos);

        for radius=0:.4:2;
            nh=cosmo_spherical_neighborhood(ds,...
                        'radius',radius,...
                        'progress',false);
            center_pos=nh.a.fdim.values{1}(:,nh.fa.pos);
            assertEqual(numel(nh.neighbors),n_keep);
            for k=1:n_keep
                sel_idx=nh.neighbors{k};

                delta=bsxfun(@minus,center_pos(:,k),...
                                     ds_pos);
                distance=sqrt(sum((delta/voxel_size).^2,1));

                expected_sel_idx=find(distance<=radius & ds.fa.inside);

                assertEqual(sort(sel_idx(:)),sort(expected_sel_idx(:)));
            end
        end
    end

function test_meeg_source_illegal_inside()
    ds=cosmo_synthetic_dataset('type','source','size','small');
    n_features=size(ds.samples,1);

    illegal_values={min(max(ds.samples(1,:),0),1),...
                    repmat({'foo'},1,n_features)};
    for k=1:numel(illegal_values)
        ds.fa.inside=illegal_values{k};

        assertExceptionThrown(@()...
                cosmo_spherical_neighborhood(ds,'radius',1),'');
    end

function test_meeg_missing_dimension_label()
    ds=cosmo_synthetic_dataset();
    ds=cosmo_dim_remove(ds,'i');
    assertExceptionThrown(@()...
                cosmo_spherical_neighborhood(ds,'radius',1),'');

function test_meeg_wrong_dimension_order()
    ds=cosmo_synthetic_dataset();
    ds.fa.j(:)=1;
    ds.fa.k(:)=1;
    ds.a.fdim.labels([2,3])=ds.a.fdim.labels([3,2]);
    assertExceptionThrown(@()...
                cosmo_spherical_neighborhood(ds,'radius',1),'');

function test_meeg_source_sdim_time
    ds=cosmo_synthetic_dataset('type','source','size','big');
    ds_time=cosmo_dim_transpose(ds,'time',1);
    nh=cosmo_spherical_neighborhood(ds_time,'radius',0,'progress',false);

    assert(~isfield(nh.a,'sdim'));
    assert(~isfield(nh,'sa'));



function test_fmri_fixed_number_of_features()
    ds=cosmo_synthetic_dataset('size','normal');
    nf=size(ds.samples,2);
    [unused,idxs]=sort(cosmo_rand(1,nf*3,'seed',1));
    rps=mod(idxs-1,nf)+1;
    id_full=rps(round(nf/2)+(1:(2*nf)));
    ds_full=cosmo_slice(ds,id_full,2);

    id_idxs=cosmo_index_unique(id_full');
    id_idx=cellfun(@(x)x(1),id_idxs);
    ds_sel=cosmo_slice(ds_full,id_idx,2);

    count=20;
    nh=cosmo_spherical_neighborhood(ds_full,'count',count,...
                                        'progress',false);
    ijk_sel={ds_sel.fa.i; ds_sel.fa.j; ds_sel.fa.k};
    ijk_nh={nh.fa.i; nh.fa.j; nh.fa.k};

    mp=cosmo_align(ijk_sel,ijk_nh);
    ds_al=cosmo_slice(ds_sel,mp,2);
    assertEqual(nh.fa.i,ds_al.fa.i);
    assertEqual(nh.fa.j,ds_al.fa.j);
    assertEqual(nh.fa.k,ds_al.fa.k);

    pos_nh=[nh.fa.i; nh.fa.j; nh.fa.k];
    pos_full=[ds_full.fa.i;ds_full.fa.j;ds_full.fa.k];

    rp=randperm(numel(id_idx));
    rp=rp(1:10);
    for r=rp
        d=sum(bsxfun(@minus,pos_nh(:,r),pos_full).^2,1).^.5;
        idxs=nh.neighbors{r};
        d_inside=d(idxs);
        d_outside=d(setdiff(1:nf,idxs));
        assert(max(d_inside)<=min(d_outside));
        assertElementsAlmostEqual(max(d_inside),nh.fa.radius(r),...
                                                'absolute',1e-4);
    end




