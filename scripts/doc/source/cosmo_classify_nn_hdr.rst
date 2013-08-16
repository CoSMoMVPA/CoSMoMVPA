.. cosmo_classify_nn_hdr

cosmo classify nn hdr
=====================
.. code-block:: matlab

    function predicted=cosmo_classify_nn(samples_train, targets_train, samples_test, opt)
    % nearest neighbor classifier
    %
    % predicted=cosmo_classify_nn(samples_train, targets_train, samples_test[, opt])
    %
    % Inputs
    % - samples_train      PxR training data for P samples and R features
    % - targets_train      Px1 training data classes
    % - samples_test       QxR test data
    %-  opt                (currently ignored)
    %
    % Output
    % - predicted          Qx1 predicted data classes for samples_test
    %
    % NNO Aug 2013