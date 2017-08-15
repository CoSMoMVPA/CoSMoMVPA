function test_suite = test_singleton_neighborhood
% tests for test_singleton_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function i=randint()
    i=ceil(rand()*10+10);


function s=randstr()
    s=char(ceil(rand(1,10)*26+64));


function test_singleton_neighborhood_basics
    nf=randint();
    ns=randint();

    ds=struct();
    ds.samples=rand(ns,nf);

    ds.a.(randstr())=randstr();
    ds.fa.(randstr())=rand(randint(),nf);
    ds.sa.(randstr())=rand(ns,randint());

    expected_nh=struct();
    expected_nh.neighbors=num2cell((1:nf)');
    expected_nh.fa=ds.fa;
    expected_nh.a=ds.a;
    expected_nh.origin.fa=expected_nh.fa;
    expected_nh.origin.a=expected_nh.a;
    expected_nh.fa.sizes=ones(1,nf);

    nh=cosmo_singleton_neighborhood(ds);
    assertEqual(nh,expected_nh);

function test_singleton_neighborhood_tiny()
    nf=randint();

    ds=struct();
    ds.samples=rand(1,nf);

    expected_nh=struct();
    expected_nh.neighbors=num2cell((1:nf)');
    expected_nh.origin=struct();
    expected_nh.fa.sizes=ones(1,nf);
    expected_nh.a=struct();

    nh=cosmo_singleton_neighborhood(ds);
    assertEqual(nh,expected_nh);




function test_singleton_neighborhood_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                       cosmo_singleton_neighborhood(varargin{:}),'');
    ds=cosmo_synthetic_dataset();

    % not a dataset
    ds_bad=struct();
    aet(ds_bad);

    % missing .fa field
    ds_bad=ds;
    ds_bad.fa=rmfield(ds_bad.fa,'i');
    aet(ds_bad);
