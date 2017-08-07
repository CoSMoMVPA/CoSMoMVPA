function test_suite=test_find_local_extrema
% tests for cosmo_find_local_extrema
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite

function test_find_local_maxima_basics
    % generate tiny dataset with 6 voxels
    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',1);
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
    % find local maxima within neighborhood of 1 voxel radius
    [feature_ids,scores]=cosmo_find_local_extrema(ds,nh);
    assertEqual(feature_ids,[1 5 3]);
    assertElementsAlmostEqual(scores,[2.0317 1.1908 -1.4437],...
                                        'absolute',1e-4);

    % only return two feature ids
    [feature_ids,scores]=cosmo_find_local_extrema(ds,nh,'count',2);
    assertEqual(feature_ids,[1 5]);
    assertElementsAlmostEqual(scores,[2.0317 1.1908],...
                                        'absolute',1e-4);

    % use another fitness function, namely local minima
    [feature_ids,scores]=cosmo_find_local_extrema(ds,nh,'fitness',@min);
    assertEqual(feature_ids,[3 4]);
    assertElementsAlmostEqual(scores,[-1.4437 -0.5177 ],...
                                        'absolute',1e-4);

    nh=cosmo_spherical_neighborhood(ds,'radius',2,'progress',false);
    [feature_ids,scores]=cosmo_find_local_extrema(ds,nh);
    assertEqual(feature_ids,[1 6]);
    assertElementsAlmostEqual(scores,[2.0317 -1.3265],...
                                        'absolute',1e-4);

    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
    ds.samples(:)=NaN;
    [feature_ids,scores]=cosmo_find_local_extrema(ds,nh);
    assertEqual(feature_ids,zeros(1,0));
    assertElementsAlmostEqual(scores,zeros(1,0));


function test_find_local_maxima_exceptions
    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',1);
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);

    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_find_local_extrema(varargin{:}),'');
    aet(cosmo_stack({ds,ds}),nh)
    ds.fa.i=ds.fa.i(end:-1:1);
    aet(ds,nh)

    ds.fa.i=ds.fa.i(end:-1:1);

    nh.a=struct();
    ds.samples=1;
    aet(ds,nh);

