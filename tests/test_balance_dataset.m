function test_suite = test_balance_dataset
% tests for cosmo_average_samples
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function r=randint()
    r=ceil(rand()*10+10);


function test_balance_dataset_basics
    nclasses=randint();

    ds_cell=cell(nclasses,1);
    nreps=zeros(nclasses,1);
    classes=zeros(nclasses,1);

    class_id=0;
    for k=1:nclasses
        nrep=randint();
        class_id=class_id+randint();

        nreps(k)=nrep;
        classes(k)=class_id;
        ds_k=cosmo_synthetic_dataset('nchunks',1,...
                                    'ntargets',1,...
                                    'nreps',nrep,...
                                    'seed',0);
        ds_k.sa.targets(:)=class_id;

        ds_cell{k}=ds_k;
    end

    ds=cosmo_stack(ds_cell);
    nsamples=numel(ds.sa.chunks);
    ds.sa.chunks(:)=1:nsamples;
    ds.sa.samples(:,1)=1:nsamples;

    [unused,i]=sort(randn(nsamples,1));
    ds=cosmo_slice(ds,i);

    [balanced_ds,idxs,balanced_classes]=cosmo_balance_dataset(ds);

    assertEqual(unique(classes),balanced_classes);
    assertEqual(cosmo_slice(ds,idxs(:),1),balanced_ds);
    assertEqual(size(idxs),[min(nreps),nclasses]);

    for k=1:nclasses
        msk=balanced_ds.sa.targets==classes(k);

        % correct number of selected samples
        assertEqual(sum(msk),min(nreps));

        % all selected samples are different
        assertEqual(unique(balanced_ds.samples(msk,1)),...
                        sort(balanced_ds.samples(msk,1)));
    end






function test_balance_dataset_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_balance_dataset(varargin{:}),'');
    ds=cosmo_synthetic_dataset('ntargets',randint());
    nsamples=size(ds.samples,1);
    ds.sa.chunks(:)=1:nsamples;

    % this should be ok
    cosmo_balance_dataset(ds);

    % not a dataset
    aet(struct)

    % not all chunks unique raises an exception
    bad_ds=ds;
    bad_ds.sa.chunks(1)=bad_ds.sa.chunks(2);
    aet(bad_ds);

    % missing samples
    bad_ds=rmfield(ds,'samples');
    aet(bad_ds)

    % missing targets
    bad_ds=ds;
    bad_ds.sa=rmfield(bad_ds.sa,'targets');
    aet(bad_ds);

    % missing chunks
    bad_ds=ds;
    bad_ds.sa=rmfield(bad_ds.sa,'targets');
    aet(bad_ds);