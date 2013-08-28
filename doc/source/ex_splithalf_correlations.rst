Split-half correlation-based MVPA with group analysis
=====================================================

Background
++++++++++
This exercise the most simple and most popular type of MVPA, that was first reported in Haxby et al 2001.
The intuition is to split the data in two halves (e.g. odd and even runs) and estimate the response for each category, voxel and half seperately. If an area represents categories in a distributed manner (over voxels), then correlations (over voxels) of matching categories may be higher than correlations of non-matching categories. If categories are not represented in such a way, one would expect no differences between correlations of matching and non-matching categories.

Exercise
++++++++
In this exercise data we use the handy functionality that cosmo_fmri_dataset_ provided us with. 

Using the function cosmo_fmri_dataset load, for each participant seperately the t stats for 'odd' and 'even' runs, while supplying the VT mask. The stimulus labels for each run of the fMRI study were
monkey, lemur, mallard, warbler, ladybug, and lunamoth -- in that order. These
two nifti files contain summary statistics (T statistics from the general linear model
analysis, GLM) for each stimulus for odd and even runs, respectively.

Apply the VT mask to each half, then compute all pairwise correlations between patterns in the first and the second half, resulting in a 6x6 matrix. After applying a Fisher transform, compute the mean difference between 
values on the diagonal and those off the diagonal. If there is no category information one would expect a difference of zero, on average. Run a t-test across participants for this difference to see if there is category information. 

Hint: run_splithalf_correlations_skl_
    
Solution: run_splithalf_correlations_ / run_splithalf_correlations_pb_

Extra exercise: compute the same statistic using the EV and the whole brain mask.

Advanced exercise: plot an image of the 6x6 correlation matrix averaged over participants.

.. _run_splithalf_correlations_skl: run_splithalf_correlations_skl.html
.. _run_splithalf_correlations: run_splithalf_correlations.html
.. _run_splithalf_correlations_pb: _static/publish/run_splithalf_correlations.html
.. _cosmo_fmri_dataset: cosmo_fmri_dataset.html

