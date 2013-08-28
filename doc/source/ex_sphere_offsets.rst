.. ex_sphere_offsets

Define voxel selection for a searchlight
===========================================================
In a searchlight (Kriegeskorte et al 2006) one computes a (spatially) locally contrained measure for each feature in a dataset.

An important building block for a searchlight is the voxel selection part: for each feature, decide which features are in its neighborhood. Typically the neighborhood is defined as a sphere of a certain radius.

Compute voxel offsets in a sphere
+++++++++++++++++++++++++++++++++

In turn, computing the relative offsets from a voxel location is a building block for feature selection part. In this exercise, write a function that returns the voxel indices relative to the origin.
That is, given a radius r, it returns a Px3 array where every row (i,j,k) is unique and it holds that (i,j,k) is at most at distance r from the origin (0,0,0). This function has the following signature:

.. include:: cosmo_sphere_offsets_hdr.rst

Then, for each radius from 2 to 6 in steps of .5, plot the indices and show how many voxels are in a sphere of that raidus.

Hint: cosmo_sphere_offsets_skl_ / run_sphere_offsets_skl_

Solution: cosmo_sphere_offsets_ / run_sphere_offsets_ / run_sphere_offsets_pb_

Using the sphere offsets for voxel selection
++++++++++++++++++++++++++++++++++++++++++++
If you are up for quite an advanced exercise: write a function that performs voxel selection  (if not, don't spend your time on this and just look at the answer). It should have the following signature:

.. include:: cosmo_spherical_voxel_selection_hdr.rst

Solution: cosmo_spherical_voxel_selection_

More advanced exercise: modify this function so that it returns neighborhoods of the same size (i.e. same number of voxels) at each location.


.. _cosmo_sphere_offsets_hdr: cosmo_sphere_offsets.html
.. _cosmo_sphere_offsets_skl: cosmo_sphere_offsets_skl.html
.. _cosmo_sphere_offsets: cosmo_sphere_offsets.html
.. _run_sphere_offsets_skl: run_sphere_offsets_skl.html
.. _run_sphere_offsets: run_sphere_offsets.html
.. _run_sphere_offsets_pb: _static/publish/run_sphere_offsets.html
.. _cosmo_spherical_voxel_selection: cosmo_spherical_voxel_selection.html

