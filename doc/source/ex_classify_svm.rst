.. ex_classify_svm

Build wrapper for Matlab's SVM classifier
=========================================

Wrapper for two classes
+++++++++++++++++++++++
*Note*: this exercise requires the Matlab statistics toolbox.

Matlab_ has an implementation of a support vector machine classifier that supports two classes. Its implementation uses
two functions: ``svmtrain`` and ``svmclassify``. Have a look at these functions' signatures (``help svmtrain`` and ``help svmclassify``) and then write a wrapper that will have the same function signature as our
generic classifer, but uses matlab's SVM inside.  Below is the signature and
function header for our new function. 

Test your solution using the first part of :ref:`run_classify_svm`

.. include:: matlab/cosmo_classify_svm_2class_sgn.txt

Hint: :ref:`cosmo_classify_svm_2class_skl`

Solution: :ref:`cosmo_classify_svm_2class` / first part of :ref:`run_classify_svm`

Wrapper for multiple classes
++++++++++++++++++++++++++++
Other classifiers (such as naive bayesian) support more than two classes. SVM classifiers can be used for multi-class problems. One approach is to classify based on all possible pairs of classes, and then take as the predicted class the one that was predicted most often. Thus, write a wrapper with the same function signature as the naive bayesian classifier but that uses the 2-class SVM classifier above.
Test your solution using the second part of :ref:`run_classify_svm`.

.. include:: matlab/cosmo_classify_svm_sgn.txt

Hint: :ref:`cosmo_classify_svm_skl`

Solution: :ref:`cosmo_classify_svm_skl` / :ref:`run_classify_svm`

Extra exercise: write another multi-class SVM classifier that predicts using a one-versus-all scheme.

Extra exercise: compare the results from :ref:`run_classify_svm` with an SVM classifier to those of :ref:`cosmo_classify_naive_bayes`.

.. include:: links.rst
