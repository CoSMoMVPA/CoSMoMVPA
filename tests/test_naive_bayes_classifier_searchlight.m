function test_suite=test_naive_bayes_classifier_searchlight
    initTestSuite;

function test_naive_bayes_classifier_searchlight_basics
    ds=cosmo_synthetic_dataset('ntargets',25,'nchunks',4,'size','small');
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
    opt=struct();
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.output='predictions';
    opt.progress=false;

    x=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);
    assertEqual(x.fa,nh.fa);
    assertEqual(x.a,nh.a);

    % compare with standard searchlight
    opt.classifier=@cosmo_classify_naive_bayes;
    y=cosmo_searchlight(ds,nh,@cosmo_crossvalidation_measure,opt);

    assertEqual(x,y);

    opt.output='accuracy';
    xacc=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);
    assertEqual(xacc.samples,mean(bsxfun(@eq,x.samples,x.sa.targets)));

function test_naive_bayes_classifier_searchlight_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_naive_bayes_classifier_searchlight(varargin{:}),'');

    ds=cosmo_synthetic_dataset('size','small','nchunks',4);
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
    opt.partitions=cosmo_nchoosek_partitioner(ds,2);

    aet(ds,nh,opt);

    opt.output='foo';
    aet(ds,nh,opt);

    opt.output='accuracy';
    ds=cosmo_slice(ds,ds.sa.chunks<=2);
    opt.partitions=cosmo_nfold_partitioner(ds);
    aet(ds,nh,opt);

function test_naive_bayes_classifier_searchlight_partial_partitions
    nchunks=4;
    ds=cosmo_synthetic_dataset('ntargets',5,'nchunks',nchunks,...
                        'size','small');
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false)
    partitions=cosmo_nfold_partitioner(ds);
    for k=1:nchunks
        partitions.test_indices{k}=partitions.test_indices{k}(2:end);
    end

    opt=struct();
    opt.progress=false;
    opt.partitions=partitions;
    opt.output='predictions';

    res=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);
    assertEqual(res.sa,ds.sa);
    cosmo_check_dataset(res);






