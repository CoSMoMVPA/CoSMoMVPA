function test_suite=test_normalize
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
                            %
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
%
    % z-score along first dimension
    dsn=cosmo_normalize(ds,'zscore',1);
    aoe(dsn.samples, [  -1.2649     -1.2649     -1.2649;...
                        -0.6325    -0.6325    -0.632;...
                             0         0         0;...
                         0.6325     0.6325     0.6325;...
                          1.2649      1.2649      1.2649 ]);
%
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


