.. cosmo_classify_svm_hdr

cosmo classify svm hdr
======================
.. code-block:: matlab

    function predicted=cosmo_classify_svm(samples_train, targets_train, samples_test, opt)
    % SVM classifier that uses classify_svm_2class to provide 
    % multi-class classification with SVM.
    %
    % predicted=cosmo_classify_meta_multiclass(samples_train, targets_train, samples_test, opt)
    %
    % Inputs
    %   samples_train      PxR training data for P samples and R features
    %   targets_train      Px1 training data classes
    %   samples_test       QxR test data
    %   opt                struct with a field .base_classifier, which should 
    %                      be a function handle to another classifier
    %                      (for example opt.base_classifier=@cosmo_classify_svm)
    %
    % Output
    %   predicted          Qx1 predicted data classes for samples_test
    %
    % NNO Aug 2013