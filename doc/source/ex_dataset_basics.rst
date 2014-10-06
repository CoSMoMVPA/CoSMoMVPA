.. ex_dataset_basics

Dataset basics
==============


Nifti basics
++++++++++++

Make sure your setup works
--------------------------
Before loading any data, please make sure that you:

     - have the most recent CoSMoMVPA code (see :ref:`download`).
     - have a recent version of the :ref:`tutorial data <get_tutorial_data>`.
     - have set paths properly in ``.cosmomvpa.cfg`` (described :ref:`here <set_cosmovmpa_cfg>`)
     - have :ref:`tested <test_local_setup>` that you can load and save data from and to the paths in ``.cosmomvpa.cfg``.

Load and view anatomical dataset
--------------------------------
Before loading data with :ref:`CoSMoMVPA functions <modindex>`, we start loading a single NIFT image of an anatomical scan.
Use the function ``load_nii`` to load the nifti file of the brain of subject s01 (``brain.nii``) and assign the result to a struct 'ni'. What is contained in this struct?

Make a histogram of the non-zero voxels of the brain. There are two 'bumps' - what do they represent?

Display a saggital, axial and coronal slice.

Hint: :ref:`run_nifti_basics_skl`

Solution: :ref:`run_nifti_basics` / :pb:`nifti_basics`


Loading datasets with different masks
+++++++++++++++++++++++++++++++++++++
Before starting this exercise, please make sure you have read about:

- :ref:`cosmomvpa_dataset`
- :ref:`cosmomvpa_targets`
- :ref:`cosmomvpa_chunks`
- :ref:`cosmomvpa_dataset_operations`

Using the function in :ref:`cosmo_fmri_dataset` load the dataset for subject s01
(``glm_T_stats_perrun.nii``).

- Set the ``.sa.targets``, ``.sa.chunks`` and ``.sa.labels``:

    + The stimulus labels for each run of the fMRI study were monkey, lemur, mallard, warbler, ladybug, and lunamoth -- in that order. This dataset contains summary statistics (T statistics from the general linear model analysis, GLM) for each stimulus for each of ten runs. The runs are vertically stacked by run. For example, the first row contains the summary voxel-wise responses for monkey in run 1, the second row contains that for lemur in run 1, and the seventh row contains monkey from run 2, etc.

    + Add samples atributes (dataset.sa) that contain:

        # numeric labels for the targets,aka stimulus labels, in the samples attribute field dataset.sa.targets
        # add another sample attribute for the chunks, aka run labels, in the field dataset.sa.chunks.
        # optional: add a third sample attribute with labels (string representation) showing human-readable labels of the conditions.

- Load the VT mask, find where there are non-zero values in the mask, and apply it to the dataset using :ref:`cosmo_slice`.

- Now use :ref:`cosmo_fmri_dataset`  with the ``mask``, ``targets`` and ``chunks`` parameters, and verify you get the same as before.

- Slice samples in various ways (using :ref:`cosmo_slice`):

    + Get data in chunks 1 and 2
    + Get data in conditions 1 and 3 (monkeys and mallards)


Hint: :ref:`run_dataset_basics_skl`

Solution: :ref:`run_dataset_basics` / :pb:`dataset_basics`

Operations on datasets
++++++++++++++++++++++

Now that you are familiar with the dataset, let's play around a little. Load the
``glm_T_stats_perrun.nii`` data with the VT mask for any subject. Now slice the dataset into
datasets: one that has all the primates results (monkey and lemur) and on that
has only the bugs data (ladybug and lunamoth). Calculate the average pattern for
primates and the average pattern for bugs. Now subtract bugs from primates. Save
the result as a dataset. Now convert the dataset into a nifti format using the
function :ref:`cosmo_map2fmri`. Visualize the results using ``imagesc`` or :ref:`cosmo_plot_slices`, or save the
nifti as a file and use some other software like AFNI's or FSL's viewer.

Optional exercise: use a whole-brain mask.

Hint: :ref:`run_operations_on_datasets_skl`

Solution: :ref:`run_operations_on_datasets` / :pb:`operations_on_datasets`

