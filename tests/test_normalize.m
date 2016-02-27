function test_suite=test_normalize
% tests for cosmo_normalize
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_normalize_basics()

    aoe=@(x,y)assertElementsAlmostEqual(x,y,'absolute',1e-3);

    ds=struct();
    ds.samples=reshape(1:15,5,3)*2;

    % demean along first dimension
    dsn=cosmo_normalize(ds,'demean',1);
    aoe(dsn.samples,   [ -4        -4        -4;...
                         -2        -2        -2;...
                          0         0         0;...
                          2         2         2;...
                          4         4         4 ]);

    dsn2=cosmo_normalize(ds,'demean');
    aoe(dsn.samples,dsn2.samples);

    % demean along second dimension
    dsn=cosmo_normalize(ds,'demean',2);
    aoe(dsn.samples, [ -10         0        10;...
                        -10         0        10;...
                        -10         0        10;...
                        -10         0        10;...
                        -10         0        10 ]);

    %
    % scale to range [-1,1] alnog first dimension
    dsn=cosmo_normalize(ds,'scale_unit',1);
    aoe(dsn.samples, [   -1        -1        -1;...
                        -0.5      -0.5      -0.5;...
                           0         0         0;...
                         0.5      0.5       0.5;...
                           1         1         1 ]);
    dsn2=cosmo_normalize(ds,'scale_unit');
    aoe(dsn.samples,dsn2.samples);

    % z-score along first dimension
    dsn=cosmo_normalize(ds,'zscore',1);
    aoe(dsn.samples, [  -1.2649     -1.2649     -1.2649;...
                        -0.6325    -0.6325    -0.632;...
                             0         0         0;...
                         0.6325     0.6325     0.6325;...
                          1.2649      1.2649      1.2649 ]);
    dsn2=cosmo_normalize(ds,'zscore');
    aoe(dsn.samples,dsn2.samples);

    % z-score along second dimension
    dsn=cosmo_normalize(ds,'zscore',2);
    aoe(dsn.samples, [ -1         0         1;...
                        -1         0         1;...
                        -1         0         1;...
                        -1         0         1;...
                        -1         0         1 ])
    %
    % use samples 1, 3, and 4 to estimate parameters ('training set'),
    % and apply these to samples 2 and 5
    ds_train=cosmo_slice(ds,[1 3 4]);
    ds_test=cosmo_slice(ds,[2 5]);
    [dsn_train,params]=cosmo_normalize(ds_train,'scale_unit', 1);
    aoe(dsn_train.samples, [    -1        -1        -1;...
                                    0.3333     0.3333     0.3333;...
                                        1         1         1 ])
    p.method='scale_unit';
    p.dim=1;
    p.min=[ 2        12        22 ];
    p.max=[ 8        18        28 ];
    assertEqual(params,p);
    %
    % apply parameters to test dataset
    dsn_test=cosmo_normalize(ds_test,params);
    aoe(dsn_test.samples,[ -0.3333    -0.33333    -0.33333;...
                            1.6667      1.6667    1.6667 ]);



    [tr,params]=cosmo_normalize(zeros(4,0),'zscore');
    te=cosmo_normalize(zeros(2,0),params);
    assertEqual(tr,zeros(4,0));
    assertEqual(te,zeros(2,0));

    [tr,params]=cosmo_normalize(zeros(4,0),'demean');
    te=cosmo_normalize(zeros(2,0),params);
    assertEqual(tr,zeros(4,0));
    assertEqual(te,zeros(2,0));

    [tr,params]=cosmo_normalize(zeros(4,0),'scale_unit');
    te=cosmo_normalize(zeros(2,0),params);
    assertEqual(tr,zeros(4,0));
    assertEqual(te,zeros(2,0));

    dsn=cosmo_normalize(ds,'');
    assertEqual(dsn,ds);

    warning_state=cosmo_warning();
    warning_resetter=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    ds.samples(1,1)=NaN;
    dsn=cosmo_normalize(ds,'zscore');
    assert(all(isnan(dsn.samples(:,1))));
    assert(all(all(~isnan(dsn.samples(:,2:3)))));


function test_normalize_exceptions()
    ds=cosmo_synthetic_dataset();
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_normalize(ds,varargin{:}),'');

    aet('zscore3');
    aet('zscore2');
    aet('zscore1');
    aet('foo');
    aet('zscore1',1);
    aet('zscore1',2);

    [unused,params]=cosmo_normalize(ds,'zscore',1);
    aet(params,2);

    aet({'foo'});



