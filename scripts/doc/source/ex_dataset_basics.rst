.. ex_dataset_basics

Dataset basics
==============

Load dataset and set fields
+++++++++++++++++++++++++++
Copy and paste the function in cosmo_fmri_dataset_ into a new file called
*cosmo_fmri_dataset.m*. Load a dataset from the data folder using the
cosmo_fmri_dataset_ function, applying one of the 3 masks provided (brain, early
vision 'ev' or ventral temporal 'vt'. Add numeric chunks and targets. The
stimulus labels for each run of the fMRI study were monkey, lemur, mallard,
warbler, ladybug, and lunamoth -- in that order.  

Solution: run_dataset_basics_

.. _run_dataset_basics: run_dataset_basics.html

Slice by samples
++++++++++++++++
Write a function with the following signature.

.. literalinclude:: cosmo_dataset_slice_samples_hdr.m
   :language: matlab

.. _cosmo_dataset_slice_samples: cosmo_dataset_slice_samples.html
Solution: cosmo_dataset_slice_samples_

Slice by features
+++++++++++++++++
Write another function with the signature.

.. literalinclude:: cosmo_dataset_slice_features_hdr.m
    :language: matlab      

.. _cosmo_dataset_slice_features: cosmo_dataset_slice_features.html

Solution: cosmo_dataset_slice_features_

.. _cosmo_fmri_dataset: cosmo_fmri_dataset.html


