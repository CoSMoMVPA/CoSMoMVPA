function test_suite=test_meeg_chan_neighbors()
    initTestSuite;

function test_meeg_chan_neighbors_fieldtrip_correspondence()
    props=get_props();
    n=numel(props);

    warning_state=warning('query','all');
    cleaner=onCleanup(@()warning(warning_state));
    warning('off','all');

    ntest=2;
    rp=randperm(n);
    for k=1:ntest
        prop=props{rp(k)};
        sens=prop{1};
        chantype=prop{2};
        arg=prop(3:4);
        layout=prop{5};

        ds=cosmo_synthetic_dataset('type','meeg','sens',sens,...
                                'size','huge','ntargets',1,'nchunks',1);

        x=cosmo_meeg_chan_neighbors(ds,'chantype',chantype,arg);

        cfg=struct();
        cfg.layout=layout;
        switch arg{1}
            case 'delaunay'
                cfg.method='triangulation';
            case 'radius'
                cfg.method='distance';
                cfg.neighbourdist=arg{2};
            otherwise
                assert(false);
        end
        y=ft_prepare_neighbours(cfg);

        assertEqual({x.label},{y.label});

        [p,q]=cosmo_overlap({x.neighblabel},{y.neighblabel});
        dp=diag(p);
        dq=diag(q);
        assert(mean(dp(isfinite(dp)))>.9);
        assert(mean(dq(isfinite(dq)))>.8);
    end


function props=get_props()
    props={{'neuromag306_all','meg_axial','delaunay',true,...
                                'neuromag306mag.lay'},...
           {'neuromag306_planar','meg_planar','radius',.1,...
                                'neuromag306planar.lay'},...
           {'eeg1020',[],'radius',.4,'EEG1020.lay'},...
           {'4d148','meg_planar_combined','delaunay',true,'4D148.lay'}};
