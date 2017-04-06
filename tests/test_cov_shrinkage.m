function test_suite=test_cov_shrinkage
% tests for cosmo_cov_shrinkage
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_shrinkage_regression
    % pseudo-random numbers from norminv(cosmo_rand(10,5,'seed',1))
    x_tr=...
        [ -0.209518    -0.203955     0.844284     -1.29103       2.2856;...
           0.583806     0.482345      1.85584    -0.199061     0.668728;...
           -3.68495    -0.825823    -0.486168       1.7267    -0.581523;...
          -0.517704      1.16563     0.502445     0.083229     0.803923;...
           -1.05045     -1.92066      1.15712     0.501178     -1.26338;...
           -1.32649     0.441204      1.25141    -0.480276    -0.130985;...
          -0.891762    -0.208793     -1.37192     0.485956      1.33216;...
          -0.397334     0.147648     -1.76176     0.972607    -0.542857;...
          -0.261723     -1.07858    -0.954836     -2.09046    -0.559896;...
          0.0974532    -0.848422      1.16575     0.674944     -1.12626 ];

    % Reference values computed in scipy using the following code
    % (as preparation, x=x_tr' was saved in a file 'data.mat'):
    %
    %     from sklearn.covariance.shrunk_covariance_ import \
    %                   ledoit_wolf_shrinkage as shr
    %     import numpy as np
    %     import scipy.io as sio
    %
    %     fn='data.mat'
    %
    %     d=sio.loadmat(fn)
    %     x=d['x'].T
    %
    %     for i in xrange(1,11):
    %         s=shr(x[:,:i])
    %         print '%.5f,...' % s
    %
    % Scikit-learn: Machine Learning in Python, Pedregosa et al., JMLR 12,
    % pp. 2825-2830, 2011.

    expected_shrinkages=...
                       [0.00000,...
                        0.72659,...
                        1.00000,...
                        0.98131,...
                        0.92480,...
                        0.93003,...
                        0.94224,...
                        0.88633,...
                        0.80178,...
                        0.76550,...
                        ];

    for nfeatures=1:numel(expected_shrinkages)
        % select subset of data
        x=x_tr(1:nfeatures,:)';

        [shr,mx]=cosmo_cov_shrinkage(x);
        assertElementsAlmostEqual(expected_shrinkages(nfeatures),...
                                    shr,...
                                    'absolute',1e-4);

        cv=cov(x,1);
        expected_mx=mean(diag(cv))*eye(nfeatures)*shr...
                            +(1-shr)*cv;

        assertElementsAlmostEqual(mx,expected_mx);
    end

function test_shrinkage_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_cov_shrinkage(varargin{:}),'');
    % non-numeric input
    aet(struct())

    % not 2D input
    aet(rand([2,2,2]))


