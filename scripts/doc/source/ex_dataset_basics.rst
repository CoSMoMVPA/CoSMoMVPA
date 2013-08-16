.. ex_dataset_basics

Dataset basics
==============


Nifti basics
++++++++++++

Load and view anatomical dataset
--------------------------------
Using the function load_nii load the nifti file of the brainof subject s01 (brain.nii) and assign the result to a struct 'ni'. What is contained in this struct?

Make a histogram of the non-zero voxels of the brain. There are two 'bumps' - what do they represent?

Display a saggital, axial and coronal slice.

Hint: run_nifti_basics_skl_
    
Solution: run_nifti_basics_ / run_nifti_basics_pb_

.. _run_nifti_basics_skl: run_nifti_basics_skl.html
.. _run_nifti_basics: run_nifti_basics.html
.. _run_nifti_basics_pb: publish/run_nifti_basics.html


Loading datasets with different masks
+++++++++++++++++++++++++++++++++++++
Using the function in cosmo_fmri_dataset_ load the dataset for subject s01
(*glm_T_stats_allruns.nii.gz*) and applying whole brain mask (*brain_mask.nii.gz*). How
many voxels are included in the whole brain mask?  Now load the same data
with the early visual mask (*ev_mask.nii.gz*) and then with the ventral temporal mask
(*vt_mask.nii.gz*).  How many voxels are included in those masks? 

Hint: run_load_datasets_skl_

Solution: run_load_datasets_ / run_load_datasets_pb_

Setting sample attributes: targets and chunks
+++++++++++++++++++++++++++++++++++++++++++++
Now load the dataset that has data for each run (*glm_T_stats_perrun.nii.gz*)
using any mask you like. The stimulus labels for each run of the fMRI study were
monkey, lemur, mallard, warbler, ladybug, and lunamoth -- in that order. This
dataset contains summary statistics (T statistics from the general linear model
analysis, GLM) for each stimulus for each of ten runs. The runs are vertically
stacked by run. For example, the first row contains the summary voxel-wise
responses for monkey in run 1, the second row contains that for lemur in run 1,
and the seventh row contains monkey from run 2, etc. 

Add samples atributes (dataset.sa) that contain numeric labels for the targets,
aka stimulus labels, in the samples attribute field dataset.sa.targets, and add
another samples attribute for the chunks, aka run labels, in the field
dataset.sa.chunks.

Hint: run_setting_sample_attr_skl_

Solution: run_setting_sample_attr_ / run_setting_sample_attr_pb_

Slice by samples
++++++++++++++++
Write a function with the following signature.

.. include:: cosmo_dataset_slice_sa_hdr.rst

Hint: cosmo_dataset_slice_sa_skl_

Solution: cosmo_dataset_slice_sa_

For a more *robust* solution that can handle samples attributes that use string
labels instead of numbers see Solution 2: cosmo_dataset_slice_samples_

Slice by features
+++++++++++++++++
Write another function with the signature.

.. include::  cosmo_dataset_slice_fa_hdr.rst

Hint: cosmo_dataset_slice_fa_skl_

Solution: cosmo_dataset_slice_fa_

*Robust* Solution 2: cosmo_dataset_slice_features_

Operations on datasets
++++++++++++++++++++++

Now that you are familiar with the dataset, let's play around a little. Load the
"perrun" data with the VT mask for any subject. Now slice the dataset into
datasets: one that has all the primates restuls (monkey and lemur) and on that
has only the bugs data (ladybug and lunamoth). Calculate the average pattern for
primates and the average pattern for bugs. Now subtract bugs from primates. Save
the result as a dataset. Now convert the dataset into a nifti format using the
function cosmo_map2nifti_. Visualize the results using imagesc, or save the
nifti as a file and use some other software like AFNI, or FSL's viewer.

Hint: run_operations_on_datasets_skl_

Solution: run_operations_on_datasets_ / run_operations_on_datasets_pb_

.. _run_operations_on_datasets_skl: run_operations_on_datasets_skl.html
.. _run_operations_on_datasets: run_operations_on_datasets.html
.. _run_operations_on_datasets_pb: publish/run_operations_on_datasets.html
.. _cosmo_map2nifti: cosmo_map2nifti_hdr.html
.. _cosmo_fmri_dataset: cosmo_fmri_dataset.html
.. _run_load_datasets_skl: run_load_datasets_skl.html
.. _run_load_datasets: run_load_datasets.html
.. _run_load_datasets_pb: publish/run_load_datasets.html
.. _run_setting_sample_attr_skl: run_setting_sample_attr_skl.html
.. _run_setting_sample_attr: run_setting_sample_attr.html
.. _run_setting_sample_attr_pb: publish/run_setting_sample_attr.html
.. _cosmo_dataset_slice_sa: cosmo_dataset_slice_sa.html
.. _cosmo_dataset_slice_fa: cosmo_dataset_slice_fa.html
.. _cosmo_dataset_slice_sa_skl: cosmo_dataset_slice_sa_skl.html
.. _cosmo_dataset_slice_fa_skl: cosmo_dataset_slice_fa_skl.html
.. _cosmo_dataset_slice_features: cosmo_dataset_slice_features.html
.. _cosmo_dataset_slice_samples: cosmo_dataset_slice_samples.html



