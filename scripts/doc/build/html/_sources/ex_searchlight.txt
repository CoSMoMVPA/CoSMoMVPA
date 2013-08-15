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
involved defining the sets of *neighborhood voxels*. Before trying the next
exercise, Have a look at these functions: cosmo_sphere_offsets_, and
cosmo_spherical_voxel_selection_.

With the help of these functions, write a generic searchlight function that
satisfies the following definition:

.. literalinclude:: cosmo_searchlight_hdr.m
   :language: matlab

Hint: cosmo_searchlight_skl_

Solution: cosmo_searchlight_

.. _cosmo_searchlight_skl: cosmo_searchlight_skl.html
.. _cosmo_searchlight: cosmo_searchlight.html
.. _cosmo_sphere_offsets: cosmo_sphere_offsets.html
.. _cosmo_spherical_voxel_selection: cosmo_spherical_voxel_selection.html

