function test_suite=test_naive_bayes_classifier_searchlight
% tests for cosmo_naive_bayes_classifier_searchlight
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_naive_bayes_classifier_searchlight_tiny
    ds=cosmo_synthetic_dataset('ntargets',25,'nchunks',4,'size','small');
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);

    nh.neighbors={1:size(ds.samples,2)};
    nh.fa=cosmo_slice(nh.fa,1,2,'struct');

    opt=struct();
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.output='winner_predictions';
    opt.progress=false;

    x=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);
    assertEqual(x.fa,nh.fa);
    assertEqual(x.a,nh.a);

    nfolds=numel(opt.partitions.train_indices);
    for fold=1:nfolds
        tr=opt.partitions.train_indices{fold};
        te=opt.partitions.test_indices{fold};


        pred=cosmo_classify_naive_bayes(ds.samples(tr,:),...
                                            ds.sa.targets(tr),...
                                            ds.samples(te,:));
        y=x.samples(te,:);
        assertEqual(y,pred);


    end
    % compare with standard searchlight
    assert_same_output_as_classifical_searchlight(ds,nh,opt);



function test_naive_bayes_classifier_searchlight_basics
    ds=cosmo_synthetic_dataset('ntargets',25,'nchunks',4,'size','small');
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);

    nh.neighbors={1:size(ds.samples,2)};
    nh.fa=cosmo_slice(nh.fa,1,2,'struct');


    opt=struct();
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.output='winner_predictions';
    opt.progress=false;

    x=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);
    assertEqual(x.fa,nh.fa);
    assertEqual(x.a,nh.a);

    % compare with standard searchlight
    assert_same_output_as_classifical_searchlight(ds,nh,opt);

    opt.output='accuracy';
    xacc=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);
    assertEqual(xacc.samples,mean(bsxfun(@eq,x.samples,x.sa.targets)));
    assert_same_output_as_classifical_searchlight(ds,nh,opt);


function test_naive_bayes_classifier_searchlight_multiple_pred
    ds=cosmo_synthetic_dataset('ntargets',25,'nchunks',5,'size','small');
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);

    opt=struct();
    % multiple predictions per fold
    opt.partitions=cosmo_nchoosek_partitioner(ds,2);
    opt.output='winner_predictions';
    opt.progress=false;

    x=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);
    assertEqual(x.fa,nh.fa);
    assertEqual(x.a,nh.a);

    % compare with standard searchlight
    assert_same_output_as_classifical_searchlight(ds,nh,opt);

    opt.output='accuracy';
    assert_same_output_as_classifical_searchlight(ds,nh,opt);




function assert_same_output_as_classifical_searchlight(ds,nh,opt)
    opt.progress=false;
    x=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);

    opt.classifier=@cosmo_classify_naive_bayes;
    y=cosmo_searchlight(ds,nh,@cosmo_crossvalidation_measure,opt);

    sx=x.samples;
    sy=y.samples;
    assertElementsAlmostEqual(sx,sy);

    x=rmfield(x,'samples');
    y=rmfield(y,'samples');
    assertEqual(x,y);


function test_naive_bayes_classifier_searchlight_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_naive_bayes_classifier_searchlight(varargin{:}),'');

    ds=cosmo_synthetic_dataset('size','small','nchunks',4);
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);

    opt=struct();
    opt.progress=false;
    opt.partitions=cosmo_nchoosek_partitioner(ds,2);

    opt.output='foo';
    aet(ds,nh,opt);

    % missing samples, so illegal partitions
    opt.output='winner_predictions';
    ds=cosmo_slice(ds,ds.sa.chunks<=2);
    opt.partitions=cosmo_nfold_partitioner(ds);
    aet(ds,nh,opt);

    % unsupported output
    opt.output='fold_predictions';
    ds_bad=ds;
    ds_bad=cosmo_slice(ds_bad,ds_bad.sa.chunks<=2);
    opt.partitions=cosmo_nfold_partitioner(ds_bad);
    aet(ds,nh,opt);


function test_naive_bayes_classifier_searchlight_deprecations
    ds=cosmo_synthetic_dataset('size','small','nchunks',4);
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);

    %
    opt=struct();
    opt.progress=false;
    opt.partitions=cosmo_nchoosek_partitioner(ds,2);
    opt.output='predictions';

    orig_warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(orig_warning_state));
    cosmo_warning('reset');
    cosmo_warning('off');

    % no warnings
    w=cosmo_warning();
    assertEqual(numel(w.shown_warnings),0);

    % output='predictions' is deprecated, so expect a warning
    cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);

    w=cosmo_warning();
    assertEqual(numel(w.shown_warnings),1);






function test_naive_bayes_classifier_searchlight_partial_partitions
    nchunks=4;
    ds=cosmo_synthetic_dataset('ntargets',5,'nchunks',nchunks,...
                        'size','small');
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);

    partitions=cosmo_nfold_partitioner(ds);
    nsamples=size(ds.samples,1);
    prediction_count=zeros(nsamples,1);
    for k=1:nchunks
        with_missing=partitions.test_indices{k}(2:end);
        partitions.test_indices{k}=with_missing;
        prediction_count(with_missing)=prediction_count(with_missing)+1;
    end

    opt=struct();
    opt.progress=false;
    opt.partitions=partitions;
    opt.output='winner_predictions';

    res=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);

    ds_sa=rmfield(ds.sa,'chunks');
    assertEqual(res.sa,ds_sa);
    cosmo_check_dataset(res);

    assert_same_output_as_classifical_searchlight(ds,nh,opt);

