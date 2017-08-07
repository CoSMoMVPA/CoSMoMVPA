function test_suite=test_synthetic_dataset
% tests for cosmo_synthetic_dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_synthetic_dataset_basics()
    ds=cosmo_synthetic_dataset();
    assertElementsAlmostEqual(ds.samples([1 6,1 6]),...
                             [2.0317 -1.3265 2.0317 -1.3265],...
                             'absolute',1e-4);
    assertEqual(size(ds.samples),[6 6]);
    assertEqual(sort(fieldnames(ds)),{'a';'fa';'sa';'samples'});
    assertEqual(ds.sa.targets,[1 2 1 2 1 2]');
    assertEqual(ds.sa.chunks,[1 1 2 2 3 3]');

    ds=cosmo_synthetic_dataset('seed',2);
    assertElementsAlmostEqual(ds.samples([1 6,1 6]),...
                              [2.0801 -0.4390 2.0801 -0.4390],...
                             'absolute',1e-4);

    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',2);
    assertEqual(ds.sa.targets,[1 2 3 1 2 3]');
    assertEqual(ds.sa.chunks,[1 1 1 2 2 2]');

    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',2,'chunks',4);
    assertEqual(ds.sa.targets,[1 2 3 1 2 3]');
    assertEqual(ds.sa.chunks,[4 4 4 4 4 4]');

function test_synthetic_dataset_meeg()

    ds=cosmo_synthetic_dataset('type','meeg',...
                                'sens','neuromag306_planar');
    assertEqual(ds.a.fdim.values{1},{'MEG0112','MEG0113','MEG0212'});

    ds=cosmo_synthetic_dataset('type','meeg',...
                                'sens','neuromag306_axial');
    assertEqual(ds.a.fdim.values{1},{'MEG0111','MEG0211','MEG0311'});


function test_synthetic_dataset_source()
     ds=cosmo_synthetic_dataset('type','source','data_field','mom');
     assertEqual(ds.a.fdim.labels,{'pos','mom','time'});
     assertEqual(ds.a.fdim.values{2},{'x','y','z'});

function test_synthetic_dataset_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_synthetic_dataset(varargin{:}),'');
    aet('size','foo');
    aet('type','source','data_field','foo');
    aet('type','foo');
    aet('type','meeg','sens','foo');
    aet('targets',[2 2]);
    aet('targets',1.5);
    aet('type','meeg','sens','neuromag306_foo');


