function test_suite = test_crossvalidation_measure
% tests for cosmo_crossvalidation_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_crossvalidation_measure_basics
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',4);
    ds.sa.targets=ds.sa.targets+10;
    ds.sa.chunks=ds.sa.chunks+20;

    opt=struct();
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.classifier=@cosmo_classify_lda;

    res=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res.samples,0.6250);
    assertEqual(res.sa,cosmo_structjoin('labels',{'accuracy'}));

    opt.output='accuracy';
    res2=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res,res2);

    opt.output='predictions';
    res3=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res3.samples,10+[1 2 3 4 5 5 4 6 2 4 2 6 ...
                                1 2 3 4 6 6 1 3 3 4 3 1]');
    assertEqual(res3.sa,ds.sa);

    opt.output='accuracy_by_chunk';
    res4=cosmo_crossvalidation_measure(ds,opt);
    assertElementsAlmostEqual(res4.samples,[5 2 5 3]'/6);

    opt.partitions=cosmo_nchoosek_partitioner(ds,2);
    opt.partitions.test_indices{1}=find(ds.sa.chunks==21);
    opt.partitions.test_indices{4}=find(ds.sa.chunks==22);
    opt.partitions.test_indices{5}=find(ds.sa.chunks==24);
    res5=cosmo_crossvalidation_measure(ds,opt);
    assertElementsAlmostEqual(res5.samples,[3 NaN NaN NaN]'/6);
    assertEqual(res5.sa,cosmo_structjoin('chunks',[22 NaN NaN NaN]'));

    % test different classifier
    opt.classifier=@cosmo_classify_nn;
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.output='predictions';

    res6=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res6.samples,10+[1 2 3 1 5 6 4 6 5 4 6 6 6 ...
                                    2 3 4 2 5 1 2 3 4 3 1]');
    % test normalization option
    opt.normalization='zscore';
    res7=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res7.samples,10+[1 2 3 5 5 6 4 6 5 4 6 6 6 ...
                                    2 3 4 5 5 1 5 3 1 3 1]');

    % test with averaging samples
    opt=rmfield(opt,'normalization');
    opt.average_train_count=1;
    res8=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res8.samples,10+[1 2 3 1 5 6 4 6 5 4 6 6 6 ...
                                    2 3 4 2 5 1 2 3 4 3 1]');

    opt.average_train_count=2;
    opt.average_train_resamplings=5;
    res9=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res9.samples,10+[1 2 3 4 5 6 4 6 2 4 6 6 1 ...
                                    2 3 4 5 6 1 2 3 4 5 1]');



function test_crossvalidation_measure_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_crossvalidation_measure(varargin{:}),'');
    opt=struct();
    opt.partitions=struct();
    opt.classifier=@abs;
    aet(struct,opt);

    ds=cosmo_synthetic_dataset();
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.classifier=@cosmo_classify_lda;

    aet(struct,opt)

    opt.output='foo';
    aet(ds,opt);





