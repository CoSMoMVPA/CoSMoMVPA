function test_suite = test_confusion_matrix
% tests for cosmo_confusion_matrix
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function classes=test_confusion_matrix_basics()
    nsamples=30;
    ntargets=5;
    delta=10;

    targets=[ceil(ntargets*rand(nsamples,1));randperm(ntargets)']+delta;
    predicted=[ceil(ntargets*rand(nsamples,1));randperm(ntargets)']+delta;

    [mx,classes]=cosmo_confusion_matrix(targets,predicted);

    assertEqual(classes,delta+(1:ntargets)');

    assertEqual(size(mx),[ntargets,ntargets]);

    for k=1:ntargets
        for j=1:ntargets
            count=sum(targets==(k+delta) & predicted==(j+delta));
            assertEqual(count, mx(k,j));
        end
    end

    ds=struct();
    ds.samples=predicted;
    ds.sa.targets=targets;

    [mx2,classes2]=cosmo_confusion_matrix(ds);
    assertEqual(mx,mx2);
    assertEqual(classes,classes2);

    predicted3=predicted(randperm(numel(predicted)));
    mx3=cosmo_confusion_matrix(targets,predicted3);

    ds.samples=[predicted predicted3(:)];
    [mx_both,classes3]=cosmo_confusion_matrix(ds);
    assertEqual(mx_both,cat(3,mx2,mx3));
    assertEqual(classes3,classes);

function test_confusion_matrix_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_confusion_matrix(varargin{:}),'');
    % size mismatch
    aet([1;1],1);

    % missing target
    aet([1;1],[1;2]);

    % no dataset
    aet(struct());
    aet({});

    ds=struct();
    ds.samples=1;
    aet(ds,1);
    ds.sa.targets=1;
    % second argument with dataset
    aet(ds,1);

    % missing argument with numeric
    aet(1)

    % target row vector
    aet([1 1],[1;1])
    aet([1;1],[1 1])

    % no target vector
    aet(eye(2),[1;1]);

    % no target vector
    aet(ones([2 2 2]),[1;1]);
    aet([1;1], ones([2 2 2]));

