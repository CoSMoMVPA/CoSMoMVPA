function test_suite = test_cluster_neighborhood
    initTestSuite;


function test_fmri_cluster_neighborhood

    ds=cosmo_synthetic_dataset('type','fmri','size','normal');
    nf=size(ds.samples,2);
    imsk=find(rand(1,nf)>.4);
    rp=randperm(numel(imsk));
    ds=cosmo_dim_slice(ds,[imsk(rp) imsk(rp(end:-1:1))],2);

    nh1=cosmo_cluster_neighborhood(ds,'progress',false);
    nh2=cosmo_cluster_neighborhood(ds,'progress',false,'fmri',1);

    assertEqual(nh1.a,ds.a);
    assertEqual(nh1.fa,ds.fa);

    nf=size(ds.samples,2);
    rp=randperm(nf);

    nfeatures_test=3;

    ijk=[ds.fa.i; ds.fa.j; ds.fa.k];
    feature_ids=rp(1:nfeatures_test);

    for j=1:nfeatures_test
        feature_id=feature_ids(j);
        delta=sqrt(sum(bsxfun(@minus,ijk(:,feature_id),ijk).^2,1));
        msk1=delta<sqrt(3)+.001;
        assertEqual(sort(nh1.neighbors{feature_id}),find(msk1));

        msk2=delta<sqrt(1)+.001;
        assertEqual(sort(nh2.neighbors{feature_id}),find(msk2));

    end


function test_meeg_cluster_neighborhood

    ds=cosmo_synthetic_dataset('type','timefreq','size','big');
    nf=size(ds.samples,2);
    imsk=find(rand(1,nf)>.4);
    rp=randperm(numel(imsk));
    ds=cosmo_dim_slice(ds,[imsk(rp) imsk(rp(end:-1:1))],2);
    n=numel(ds.a.fdim.values{1});
    ds.a.fdim.values{1}=ds.a.fdim.values{1}(randperm(n));
    nf=size(ds.samples,2);

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

function test_cluster_neighborhood_surface
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
    assertEqual(nh1.neighbors,{ [ 2 4 ]
                                [ 1 3 4 5 ]
                                [ 2 5 6 ]
                                [ 1 2 5 ]
                                [ 2 3 4 6 ]
                                [ 3 5 ] });
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




