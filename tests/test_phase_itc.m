function test_suite=test_phase_itc
% tests for test_phase_itc
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function r=randint()
    r=ceil(2+rand()*10);


function test_phase_itc_basics
    nclasses=randint();
    classes=1:2:(2*nclasses);

    nrepeats=randint();
    nfeatures=randint();

    ds=generate_random_dataset(classes,nrepeats,nfeatures);

    % compute expected ITC
    itc_ds=cosmo_phase_itc(ds);
    expected_samples=zeros(nclasses+1,nfeatures);
    for k=1:nclasses
        msk=ds.sa.targets==classes(k);
        expected_samples(k,:)=quick_itc(ds.samples(msk,:));
    end
    expected_samples(nclasses+1,:)=quick_itc(ds.samples);

    % construct expected dataset
    expected_itc_ds=struct();
    expected_itc_ds.samples=expected_samples;
    expected_itc_ds.sa.targets=[classes,NaN]';
    expected_itc_ds.a=ds.a;
    expected_itc_ds.fa=ds.fa;

    assert_datasets_almost_equal(itc_ds,expected_itc_ds);


function test_phase_itc_unit_length()
    % test with 'samples_are_unit_length' option
    ds=generate_random_dataset(1:10,randint(),randint());
    ds_unit=ds;
    ds_unit.samples=ds_unit.samples./abs(ds_unit.samples);

    itc_ds=cosmo_phase_itc(ds);
    itc_unit_ds=cosmo_phase_itc(ds_unit,'samples_are_unit_length',true);

    assert_datasets_almost_equal(itc_ds,itc_unit_ds);


function test_phase_itc_sdim_field
    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',3);
    ds.samples=ds.samples+1i*randn(size(ds.samples));
    ds.sa.chunks(:)=1:9;

    % add sample dimension
    ds=cosmo_dim_insert(ds,1,1,{'foo'},{[1:9]},{[1:9]'});

    itc_ds=cosmo_phase_itc(ds);
    assert(~isfield(itc_ds.a,'sdim'));
    assert(~isfield(itc_ds.sa,'foo'));


function assert_datasets_almost_equal(p,q)
    assertElementsAlmostEqual(p.samples,q.samples);

    p=rmfield(p,'samples');
    q=rmfield(q,'samples');


    assertEqual(p,q);

function ds=generate_random_dataset(classes,nrepeats,nfeatures)
    nclasses=numel(classes);
    nsamples=nclasses*nrepeats;
    sz=[nsamples,nfeatures];
    ds=struct();
    ds.samples=randn(sz)+1i*randn(sz);
    ds.sa.targets=repmat(classes,1,nrepeats)';
    ds.sa.chunks=(1:nsamples)';
    ds.a='foo';
    ds.fa.bar=1:nfeatures;

    % permute randomly
    ds=cosmo_slice(ds,cosmo_randperm(nsamples));



function itc=quick_itc(samples)
    s=samples./abs(samples);
    itc=abs(mean(s,1));



function test_phase_itc_exceptions()
    aet=@(varargin)assertExceptionThrown(...
                    @()cosmo_phase_itc(varargin{:}),'');

    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',6);
    nsamples=size(ds.samples,1);
    sz=size(ds.samples);
    ds.samples=randn(sz)+1i*randn(sz);
    ds.sa.chunks(:)=1:nsamples;
    cosmo_phase_itc(ds); % ok

     % input not imaginary
    bad_ds=ds;
    bad_ds.samples=randn(sz);
    aet(bad_ds);

    % chunks not all unique
    bad_ds=ds;
    bad_ds.sa.chunks(1)=bad_ds.sa.chunks(2);
    aet(bad_ds);

    % imbalance
    bad_ds=ds;
    bad_ds.sa.targets(:)=[repmat([1 2],1,5),[1 1]];
    aet(bad_ds);

    % bad values for samples_are_unit_length
    bad_samples_are_unit_length_cell={[],'',1,[true false]};
    for k=1:numel(bad_samples_are_unit_length_cell)
        arg={'samples_are_unit_length',...
                    bad_samples_are_unit_length_cell{k}};
        aet(ds,arg{:});
    end

    % with samples_are_unit_length=true, raise exception if some values
    % are not unit length
    aet(ds,'samples_are_unit_length',true);





