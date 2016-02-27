function test_suite = test_searchlight
% tests for cosmo_searchlight
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_searchlight_singlethread()
    opt=struct();
    opt.progress=false;
    helper_test_searchlight(opt);

function test_searchlight_matlab_multithread()
    has_function=@(x)~isempty(which(x));
    has_parallel_toolbox=all(cellfun(has_function, {'gcp','parpool'}));

    if ~has_parallel_toolbox
        cosmo_notify_test_skipped('Matlab parallel toolbox not available');
        return;
    end

    warning_state=warning();
    warning_resetter=onCleanup(@()warning(warning_state));
    warning('off');

    opt=struct();
    opt.progress=false;
    opt.nproc=2;
    helper_test_searchlight(opt);

function test_searchlight_octave_multithread()
    has_function=@(x)~isempty(which(x));
    has_parallel_toolbox=all(cellfun(has_function, {'parcellfun',...
                                                    'pararrayfun'}));

    if ~has_parallel_toolbox
        cosmo_notify_test_skipped('Octave parallel toolbox not available');
        return;
    end

    warning_state=warning();
    warning_resetter=onCleanup(@()warning(warning_state));
    warning('off');

    opt=struct();
    opt.progress=false;
    opt.nproc=2;
    helper_test_searchlight(opt);


function helper_test_searchlight(opt)

    ds=cosmo_synthetic_dataset('size','normal');
    m=any(abs(ds.samples)>3,1);
    ds=cosmo_slice(ds,~m,2);
    ds=cosmo_dim_prune(ds);

    measure=@(x,a) cosmo_structjoin('samples',size(x.samples,2));
    nh=cosmo_spherical_neighborhood(ds,'radius',2,'progress',0);

    m=cosmo_searchlight(ds,nh,measure,opt);

    assertEqual(m.samples,[8 12 10 9 12 10 16 13 12 17 14 15 ...
                            13 11 15 14 10 9 14 11 5 7 6 7]);
    assertEqual(m.fa.i,ds.fa.i);
    assertEqual(m.fa.j,ds.fa.j);
    assertEqual(m.fa.k,ds.fa.k);
    assertEqual(m.a,ds.a);

    nh2=cosmo_spherical_neighborhood(ds,'count',17,'progress',0);
    m=cosmo_searchlight(ds,nh2,measure,opt);
    assertEqual(m.samples,[17 17 17 17 17 17 17 17 17 17 18 16 ...
                                17 17 16 15 17 17 17 17 17 17 17 17]);


    measure=@cosmo_correlation_measure;

    nh3=cosmo_spherical_neighborhood(ds,'radius',2,...
                                cosmo_structjoin('progress',0));
    m=cosmo_searchlight(ds, nh3, measure,...
                            'center_ids',[4 21],opt);

    assertVectorsAlmostEqual(m.samples, [0.9742,-.0273]...
                                        ,'relative',.001);
    assertEqual(m.fa.i,[1 1]);
    assertEqual(m.fa.j,[2 1]);
    assertEqual(m.fa.k,[1 5]);

    sa=struct();
    sa.time=(1:6)';
    sdim=struct();
    sdim.values={10:15};
    sdim.labels={'time'};

    nh4=cosmo_spherical_neighborhood(ds,'radius',0,'progress',false);
    measure2=@(x,opt)cosmo_structjoin('samples',mean(x.samples,2),...
                                       'sa',sa,...
                                       'a',cosmo_structjoin('sdim',sdim));
    m2=cosmo_searchlight(ds,nh4,measure2,opt);
    assertEqual(m2.sa,sa);
    assertEqual(m2.a.sdim,sdim);
    assertElementsAlmostEqual(m2.samples,ds.samples);


function test_searchlight_partial_classification
    ds=cosmo_synthetic_dataset('nchunks',6);

    partitions=struct();
    train_msk=mod(ds.sa.chunks,2)==0;
    partitions.train_indices={find(train_msk)};
    partitions.test_indices={find(~train_msk)};

    measure=@cosmo_crossvalidation_measure;
    opt=struct();
    opt.classifier=@cosmo_classify_lda;
    opt.partitions=partitions;
    opt.progress=false;
    opt.output='predictions';


    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
    res=cosmo_searchlight(ds,nh,measure,opt);

    assertEqual(res.samples([3 4 7 8 11 12],:),NaN(6,6))
    s=res.samples([1 2 5 6 9 10],:);
    assertTrue(all(s(:)==1 | s(:)==2));



function test_searchlight_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_searchlight(varargin{:},...
                            'progress',0),'');
    ds=cosmo_synthetic_dataset();
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
    measure=@(x,opt)cosmo_structjoin('samples',mean(x.samples,2));

    aet(struct,nh,measure);
    aet(ds,ds,measure);
    aet(ds,measure,nh);

    measure_bad=@(x,opt)cosmo_structjoin('samples',mean(x.samples,1));
    aet(ds,nh,measure_bad);



function test_searchlight_progress()
    if cosmo_skip_test_if_no_external('!evalc')
        return;
    end

    ds=cosmo_synthetic_dataset();
    nh=cosmo_spherical_neighborhood(ds,'count',2,'progress',false);
    measure=@(x,opt)cosmo_structjoin('samples',mean(x.samples,2));
    f=@()cosmo_searchlight(ds,nh,measure);
    res=evalc('f();');
    assert(~isempty(strfind(res,'[####################]')));
