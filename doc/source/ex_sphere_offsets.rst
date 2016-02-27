.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. ex_sphere_offsets

Define voxel selection for a searchlight
===========================================================
In a searchlight (Kriegeskorte et al 2006) one computes a (spatially) locally contrained measure for each feature in a dataset.

An important building block for a searchlight is the voxel selection part: for each feature, decide which features are in its neighborhood. Typically the neighborhood is defined as a sphere of a certain radius.

Compute voxel offsets in a sphere
+++++++++++++++++++++++++++++++++

In turn, computing the relative offsets from a voxel location is a building block for feature selection part. In this exercise, write a function that returns the voxel indices relative to the origin.
That is, given a radius r, it returns a Px3 array where every row (i,j,k) is unique and it holds that (i,j,k) is at most at distance r from the origin (0,0,0). This function has the following signature:

.. include:: matlab/cosmo_sphere_offsets_hdr.txt

Then, for each radius from 2 to 6 in steps of .5, plot the indices and show how many voxels are in a sphere of that raidus.

Hint: :ref:`cosmo_sphere_offsets_skl` / :ref:`run_sphere_offsets_skl`

Solution: :ref:`cosmo_sphere_offsets` / :ref:`run_sphere_offsets` / :pb:`sphere_offsets`

Using the sphere offsets for voxel selection
++++++++++++++++++++++++++++++++++++++++++++
If you are up for quite an advanced exercise: write a function that performs voxel selection  (if not, don't spend your time on this and just look at the answer). It should have the following signature:

.. include:: matlab/cosmo_spherical_neighborhood_hdr.txt

As a start you can ignore the requirement that a negative value for radius should select a certain number of voxels; in other words just focus on positive values for radius.

A more advanced exercise: modify this function so that it also supports negative values for radius, which return neighborhoods of the same size (i.e. same number of voxels) at each location.

Solution: :ref:`cosmo_spherical_neighborhood`
