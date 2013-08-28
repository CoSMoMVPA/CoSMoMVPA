.. ex_classify_svm

Build wrapper for Matlab's SVM classifier
=========================================

Wrapper for two classes
+++++++++++++++++++++++
|Matlab(TM)| has an implementation of a support vector machine classifier that supports two classes. Its implementation uses
two functions: **svmtrain** and **svmclassify**. Have a look at these functions
and then write a wrapper that will have the same function signature as our
generic classifer, but uses matlab's SVM inside.  Below is the signature and
function header for our new function. 

Test your solution using the first part of run_classify_svm_

.. include:: cosmo_classify_svm_2class_hdr.rst

Hint: cosmo_classify_svm_2class_skl_

Solution: cosmo_classify_svm_ / run_classify_svm_

Wrapper for multiple classes
++++++++++++++++++++++++++++
Other classifiers (such as naive bayesian) support more than two classes. SVM classifiers can be used for multi-class problems. One approach is to classify based on all possible pairs of classes, and then take as the predicted class the one that was predicted most often. Thus, write a wrapper with the same function signature as the naive bayesian classifier but that uses the 2-class SVM classifier above.
Test your solution using the second part of run_classify_svm_


.. include:: cosmo_classify_svm_hdr.rst

Hint: cosmo_classify_svm_skl_

Solution: cosmo_classify_svm_skl_ / run_classify_svm_

Extra exercise: write another multi-class SVM classifier that predicts using a one-versus-all scheme.

Extra exercise: compare the results from run_classify_svm_ with an SVM classifier to those of classify_naive_bayes_.


.. |Matlab(TM)| unicode:: MATLAB U+00AE
.. _cosmo_classify_svm_skl: cosmo_classify_svm_skl.html
.. _cosmo_classify_svm: cosmo_classify_svm.html
.. _cosmo_classify_svm_2class_skl: cosmo_classify_svm_2class_skl.html
.. _cosmo_classify_svm_2class: cosmo_classify_svm_2class.html
.. _run_classify_svm: _static/publish/run_classify_svm.html
.. _classify_naive_bayes: cosmo_classify_naive_bayes.html
