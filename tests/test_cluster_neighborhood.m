function test_suite = test_cluster_neighborhood
    initTestSuite;


function test_fmri_cluster_neighborhood

    ds=cosmo_synthetic_dataset('type','fmri','size','normal');
    nf=size(ds.samples,2);
    imsk=find(rand(1,nf)>.8);
    rp=randperm(numel(imsk));
    ds=cosmo_slice(ds,[imsk(rp) imsk(rp(end:-1:1))],2);

    nh1=cosmo_cluster_neighborhood(ds,'progress',false);
    nh2=cosmo_cluster_neighborhood(ds,'progress',false,'fmri',1);
    nh_sph=cosmo_spherical_neighborhood(ds,'progress',false,...
                                                    'radius',2.5);
    nh3=cosmo_cluster_neighborhood(ds,'progress',false,'fmri',nh_sph);

    ds.fa.sizes=ones(1,size(ds.samples,2));
    assertEqual(nh1.a,ds.a);
    assertEqual(nh1.fa,ds.fa);

    nf=size(ds.samples,2);
    rp=randperm(nf);

    nfeatures_test=nf;

    ijk=[ds.fa.i; ds.fa.j; ds.fa.k];
    feature_ids=rp(1:nfeatures_test);

    for j=1:nfeatures_test
        feature_id=feature_ids(j);
        delta=sqrt(sum(bsxfun(@minus,ijk(:,feature_id),ijk).^2,1));
        msk1=delta<sqrt(3)+.001;
        assertEqual(sort(nh1.neighbors{feature_id}),find(msk1));

        msk2=delta<sqrt(1)+.001;
        assertEqual(sort(nh2.neighbors{feature_id}),find(msk2));

        msk3=delta<2.5;
        assertEqual(sort(nh3.neighbors{feature_id}),find(msk3));
    end


function test_meeg_cluster_neighborhood
    if cosmo_skip_test_if_no_external('fieldtrip')
        return
    end
    ds=cosmo_synthetic_dataset('type','timefreq','size','big');
    nf=size(ds.samples,2);
    imsk=find(rand(1,nf)>.4);
    rp=randperm(numel(imsk));
    ds=cosmo_dim_slice(ds,[imsk(rp) imsk(rp(end:-1:1))],2);
    n=numel(ds.a.fdim.values{1});
    ds.a.fdim.values{1}=ds.a.fdim.values{1}(randperm(n));
    nf=size(ds.samples,2);
    ds.fa.sizes=ones(1,size(ds.samples,2));


    chan_nbrhood=cosmo_meeg_chan_neighborhood(ds,'delaunay',true,...
                                                 'chantype','all',...
                                                 'label','dataset');

    assertEqual(ds.a.fdim.values(1),chan_nbrhood.a.fdim.values(1));

    ncombi=1; % test one out of 7 possibilities
    test_range=ceil(rand(1,ncombi)*7);
    nfeatures_test=3;


    for i=test_range
        use_chan=i<=4;
        use_freq=mod(i,2)==1;
        use_time=mod(ceil(i/2),2)==1;

        use_msk=[use_chan, use_freq, use_time];
        labels={'chan','freq','time'};
        ndim=numel(labels);

        args=struct();
        for k=1:ndim
            if ~use_msk(k)
                label=labels{k};
                args.(label)=false;
            end
        end


        cl_nbrhood=cosmo_cluster_neighborhood(ds,args,'progress',false);
        assertEqual(cl_nbrhood.fa,ds.fa);
        assertEqual(cl_nbrhood.a,ds.a);

        rp=randperm(nf);
        for k=1:nfeatures_test
            feature_id=rp(k);

            counter=zeros(1,nf);

            for j=1:ndim
                label=labels{j};
                fa=ds.fa.(label);
                if use_msk(j)
                    if j==1
                        % channel
                        ids=chan_nbrhood.neighbors{fa(feature_id)};
                    else
                        % anything else
                        ids=find(abs(fa-fa(feature_id))<=1.5);
                    end
                else
                    ids=find(fa==fa(feature_id));
                end

                counter(ids)=counter(ids)+1;
            end

            nbrs=find(counter==ndim);
            assertEqual(nbrs,cl_nbrhood.neighbors{feature_id});

        end
    end


function test_tiny_meeg_cluster_neighborhood
    if cosmo_skip_test_if_no_external('fieldtrip')
        return
    end
    ds=cosmo_synthetic_dataset('type','meeg');
    nh=cosmo_cluster_neighborhood(ds,'progress',false);

    ds.fa.sizes=ones(1,6);
    assertEqual(ds.fa,nh.fa);

    assertEqual(ds.a,nh.a);

    half_neighbors={[1 4];[2 3 5 6];[2 3 5 6]};
    assertEqual(nh.neighbors,repmat(half_neighbors,2,1));



function test_cluster_neighborhood_surface
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

    opt=struct();
    opt.progress=false;
    opt.vertices=vertices;
    opt.faces=faces;

    nh1=cosmo_cluster_neighborhood(ds,opt);
    assertEqual(nh1.neighbors,{ [ 1 2 4 ]
                                [ 1 2 3 4 5 ]
                                [ 2 3 5 6 ]
                                [ 1 2 4 5 ]
                                [ 2 3 4 5 6 ]
                                [ 3 5 6 ] });
    assertEqual(ds.a,nh1.a);
    ds.fa.sizes=[1 3 2 2 3 1]/6;
    ds.fa.radius=sqrt([1 2 2 2 2 1]);
    assertEqual(ds.fa,nh1.fa);

    opt.direct=false;
    nh2=cosmo_cluster_neighborhood(ds,opt);
    assertEqual(nh2.neighbors,num2cell((1:6)'));
    assertEqual(ds.a,nh2.a);
    ds.fa.radius(:)=0;
    assertEqual(ds.fa,nh2.fa);

function test_cluster_neighborhood_source
    ds=cosmo_synthetic_dataset('size','normal','type','source');
    nf=size(ds.samples,2);
    [unused,idxs]=sort(cosmo_rand(1,nf*3));
    rps=mod(idxs-1,nf)+1;
    rp=rps(round(nf/2)+(1:(2*nf)));
    ds=cosmo_slice(ds,rp,2);


    [unused,rp]=sort(cosmo_rand(1,nf));
    rp=rp(1:10);

    grid_spacing=10;
    ds_pos=ds.a.fdim.values{1}(:,ds.fa.pos)/grid_spacing;


    for connectivity=0:3
        if connectivity==0
            radius=sqrt(3)+.001;
            args={};
        else
            args={'source',connectivity};
            radius=sqrt(connectivity)+.001;
        end

        nh=cosmo_cluster_neighborhood(ds,'progress',false,args);
        nh_pos=nh.a.fdim.values{1}(:,nh.fa.pos)/grid_spacing;

        for r=rp
            idxs=nh.neighbors{r};

            d=sum(bsxfun(@minus,nh_pos(:,r),ds_pos).^2,1).^.5;

            d_inside=d(idxs);
            outside_mask=true(size(d));
            outside_mask(d <= radius)=false;
            d_outside=d(outside_mask);
            assert(all(d_inside<=radius));
            assert(all(d_outside>radius));
        end
    end


function test_cluster_neighborhood_exceptions
    ds=cosmo_synthetic_dataset();
    aet=@(varargin)assertExceptionThrown(...
                        @()cosmo_cluster_neighborhood(varargin{:},...
                                            'progress',false),'');

    aet(ds,'foo');
    aet(ds,'fmri',-1);
    aet(ds,'fmri',true);
    aet(ds,'fmri',[1 1]);

    ds.a.fdim.labels{2}='foo';
    ds.fa.foo=ds.fa.j;
    aet(ds);

    ds2=cosmo_synthetic_dataset('type','meeg');
    ds2.a.fdim.labels{1}='freq';
    ds2.fa.freq=ones(1,6);

    aet(ds2,'freq');
    aet(ds2,'freq',2);
    aet(ds2,'freq',NaN);
    aet(ds2,'freq',[true true]);





