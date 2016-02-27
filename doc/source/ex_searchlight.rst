.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. ex_searchlight

Write a searchlight function that computes a generic dataset measure
====================================================================

Volume based searchlight analysis proceeds by defining a local neighborhood of
voxels around each voxel in the brain volume. This subset of voxels can be
thought of as a mini dataset, where the mask that defines the voxels included in
the dataset is the searchlight sphere. Because we can treat each searchlight as
a dataset, we can build a searchlight function that will compute any **dataset
measure** that we specify. This allows us to reuse code, and run searchlights
for different purposes.

We have provided a couple of helper functions that do some of the heavy lifting
involved defining the sets of *neighborhood voxels*. For this, use
:ref:`cosmo_spherical_neighborhood` that was presented in the previous exercise.

With the help of these functions, write a generic searchlight function that
satisfies the following definition:

.. include:: matlab/cosmo_searchlight_hdr.txt

Hint: :ref:`cosmo_searchlight_skl`

Solution: :ref:`cosmo_searchlight`


