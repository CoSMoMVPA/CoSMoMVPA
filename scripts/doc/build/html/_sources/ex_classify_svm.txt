.. ex_classify_svm

Build wrapper for Matlab's SVM classifier
=========================================

|Matlab(TM)| has an implementation of a support vector machine classifier. That uses
two functions: **svmtrain** and **svmclassify**. Have a look at these functions
and then write a wrapper that will have the same function signature as our
generic classifer, but uses matlab's SVM inside.  Below is the signature and
function header for our new function. 

.. literalinclude:: cosmo_classify_svm_hdr.m
   :language: matlab

Hint: cosmo_classify_svm_skl_

Solution: cosmo_classify_svm_

.. |Matlab(TM)| unicode:: MATLAB U+00AE
.. _cosmo_classify_svm_skl: cosmo_classify_svm_skl.html
.. _cosmo_classify_svm: cosmo_classify_svm.html
