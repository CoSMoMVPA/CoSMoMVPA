.. exercise1

Exercise 1: Dataset basics
==========================

A. Load dataset and set fields
++++++++++++++++++++++++++++++
Copy and paste the function in fmri_dataset_ into a new file called
*cosmo_fmri_dataset.m*. Load a dataset from the example data folder using the
fmri_dataset_ function, applying one of the 3 masks provided (brain, early
vision 'ev' or ventral temporal 'vt'. Add numeric chunks and targets. The
stimulus labels for each run of the fMRI study were monkey, lemur, mallard,
warbler, ladybug, and lunamoth -- in that order.  Add a sample attribute that
stores these stimulus labels for the samples for all 10 runs (Solution_1a_).

.. _Solution_1a: solution_1a.html

B. Slice by samples
+++++++++++++++++++
Write a function with the following signature.

.. code-block:: matlab
    
        function ds =  sa_slicer(dataset, sample_indices)

        % This function returns a dataset that is a copy of the original dataset
        % but contains just the rows indictated in sample_indices

.. _Solution_1b: solution_1b.html
Solution_1b_

C. Slice by features
++++++++++++++++++++
Write another function with the signature.

.. code-block:: matlab
        
        function ds = fa_slicer(dataset, feature_indices)
        
        % Thhis function return a dataset that is a copy of the original dataset
        % but contains just the columns indictated in feature_indices

.. _Solution_1c: solution_1c.html
Solution_1c_


.. _fmri_dataset: fmri_dataset.html


