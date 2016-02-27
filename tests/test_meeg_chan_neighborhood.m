function test_suite=test_meeg_chan_neighborhood()
% tests for cosmo_meeg_chan_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_neighbors()
    % note: this tests assumes that meeg_chan_neighbors works properly
    if cosmo_skip_test_if_no_external('fieldtrip')
        return;
    end

    % only test every test_step-th channel
    test_step=10;

    ds=cosmo_synthetic_dataset('type','meeg','size','big');
    msk=ds.fa.chan<10 | mod(ds.fa.chan,5)==0 | ds.fa.chan>250;
    imsk=find(msk);
    rp=randperm(numel(imsk));
    ds=cosmo_slice(ds,imsk(rp),2);
    ds=cosmo_dim_prune(ds);
    n=numel(ds.a.fdim.values{1});
    ds.a.fdim.values{1}=ds.a.fdim.values{1}(randperm(n));

    nbrs=cosmo_meeg_chan_neighbors(ds,'chantype','meg_planar','radius',0);
    nh=cosmo_meeg_chan_neighborhood(ds,nbrs);

    assertEqual(nh.a.fdim.values,{{nbrs.label}});
    assertEqual(nh.a.fdim.labels,{'chan'});

    n=numel(nh.neighbors);
    for k=1:test_step:n
        idx=nh.neighbors{k};
        chan_label=ds.a.fdim.values{1}(ds.fa.chan(idx));
        assert(all(cosmo_match(chan_label,nh.a.fdim.values{1}{k})));
    end

    % test correspondence with neighbors
    args={'chantype','all','delaunay',true};
    nbrs=cosmo_meeg_chan_neighbors(ds,args{:});
    nh=cosmo_meeg_chan_neighborhood(ds,args{:});
    nh2=cosmo_meeg_chan_neighborhood(ds,nbrs);
    assertEqual(nh,nh2);

    ds_label=ds.a.fdim.values{1};

    n=numel(nh.neighbors);
    for k=1:test_step:n
        idx=nh.neighbors{k};

        chan_label=ds.a.fdim.values{1}(ds.fa.chan(idx));

        % ensure both arguments for intersect are column vectors,
        % because Octave behaves differently than Matlab
        assertEqual(intersect(ds_label(:),nbrs(k).neighblabel(:)),...
                        unique(chan_label'));

    end


    % try with dataset labels
    args={'chantype','all','count',5,'label','dataset'};
    nbrs=cosmo_meeg_chan_neighbors(ds,args{:});
    nh=cosmo_meeg_chan_neighborhood(ds,nbrs);
    n=numel(nh.neighbors);
    assertEqual(n, numel(ds.a.fdim.values{1}));
    assertEqual(1:n, nh.fa.chan);
    ds_label=ds.a.fdim.values{1};
    nh_label=nh.a.fdim.values{1};

    for k=1:test_step:n
        i=find(cosmo_match(nh_label,ds_label{k}));
        assertEqual(nbrs(i).label,ds_label{k});

        overlap=cosmo_overlap({ds_label(ds.fa.chan(nh.neighbors{i}))},...
                                {nbrs(i).neighblabel});
        assertEqual(overlap,1);
    end

    % test for number of channels
    nbrs=cosmo_meeg_chan_neighbors(ds,'count',5,...
                        'chantype','meg_combined_from_planar');
    nh=cosmo_meeg_chan_neighborhood(ds,nbrs);
    assertEqual(numel(nh.neighbors),102);
    h=cellfun(@numel,nh.neighbors)/7;
    assert(all(h>=5 & h<=10));
    mh=mean(h);
    assert(mh>6 && mh<9);

    nbrs=cosmo_meeg_chan_neighbors(ds,'count',5,'chantype','meg_planar');
    nh=cosmo_meeg_chan_neighborhood(ds,nbrs);
    assertEqual(numel(nh.neighbors),204);
    h=cellfun(@numel,nh.neighbors)/7;
    assert(all(h==5));


    % test tiny dataset
    ds=cosmo_synthetic_dataset('type','meeg');
    opt=struct();
    opt.delaunay=true;
    opt.label='dataset';
    opt.chantype='meg_axial';

    nh=cosmo_meeg_chan_neighborhood(ds,opt);
    assertEqual(nh.neighbors,{[1 4]});

    opt.chantype='meg_planar';
    nh=cosmo_meeg_chan_neighborhood(ds,opt);
    assertEqual(nh.neighbors,{[2 5 3 6]; [2 5 3 6]});


