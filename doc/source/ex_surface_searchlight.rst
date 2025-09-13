.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`ex_surface_searchlight`:

Surface-based fMRI searchlight
==============================

Reading material
----------------

- :cite:`OWD+11`: One of the early papers using a surface-based searchlight, with comparison between volumetric and surface-based searchlight.

Required toolboxes
------------------
- surfing toolbox: https://github.com/nno/surfing
- AFNI Matlab toolbox: https://sscc.nimh.nih.gov/pub/dist/tgz/afni_matlab.tgz (or part of the full AFNI distribution in the ``src/matlab`` directory, see https://github.com/afni/afni)

Background
++++++++++
In this exercise, data is analyzed from one participant who pressed buttons with either the index or middle finger in blocks. We try to infer where in the brain
Surface-models were reconstructed using FreeSurfer's ``recon-all``; further processing was done using AFNI and the script ``prep_afni_surf.py`` that is part of PyMVPA. Surfaces representing the left and right hemispheres were merged as described in the FAQ.


Exercise
++++++++

For this exercise use the `digit` dataset.

Part 1 (cortical thickness)
---------------------------
Load the anatomical surface models for the outer (pial) and inner (white) surfaces that separate the grey matter from non-gray matter. Compute, for each node on the surface, the cortical thickness, and then plot the thickness on a 3D surface model.

Part 2 (Classification analysis)
---------------------------------
Load the anatomical surface models and the functional data.
Define a surface-based neighborhood with approximately 100 voxels per searchlight center. Then run the searchlight with a classifier to distinguish between the different digit presses and visualize the results.

Hint: :ref:`run_surface_searchlight_skl`

Solution: :ref:`run_surface_searchlight` / :pb: surface_searchlight


.. include:: links.txt

