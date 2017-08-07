.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _intro:

Introduction
============

Overview of the workshop
++++++++++++++++++++++++
After an introductory presentation, it starts with basic operations of reading, writing, selecting, and aggregating dataset structures. This is followed by MVPA correlation and classficiation analysis of fMRI data in a region of interest. Subsequently, this is extended to exploratory searchlight analysis, representational similarity analysis, and MEEG analysis in the space and time dimensions. Finally approaches to multiple comparison are discussed.

Note: although MEEG analysis is covered only on day 2, basic concepts and functionality for MEEG analysis is discussed on day 1. Also for those who are mainly interested in MEEG analysis (and less so in fMRI) it is still recommended to attend both days.

Format
++++++
In this workshop, all material is present on the website. Each exercise part of the workshop has three parts:

- short presentation and introduction to exercise
- time to work on the exercise
- presentation of a possible solution to the exercise

Exercises are provided in the form of code skeletons, with part of the code left out as an exercise. Full solutions for all exercises are provided on the website.

Prerequisites
+++++++++++++

    * Matlab / Octave :ref:`advanced beginner level <matlab_experience>`. experience.
    * fMRI and/or MEEG :ref:`advanced beginner level <cogneuro_experience>` analysis experience.
    * Working Matlab_ or Octave_ installation.
    * Working FieldTrip_ installation (required for MEEG analysis)
    * MRI data viewer, such as MRIcron_ (strongly recommended)
    * :ref:`CoSMoMVPA source code and tutorial data <get_code_and_example_data>`.
    * It is recommended, prior to the course, to:

        + read the CoSMoMVPA manuscript (:doi:`10.1101/047118`, citation :cite:`OCH16`).
        + have the most recent CoSMoMVPA code (see :ref:`download`).
        + have a recent version of the :ref:`tutorial data <get_tutorial_data>`.
        + have set paths properly in ``.cosmomvpa.cfg`` (described :ref:`here <set_cosmovmpa_cfg>`)
        + have :ref:`tested <test_local_setup>` that you can load and save data from and to the paths in ``.cosmomvpa.cfg``.

Goals of this course
++++++++++++++++++++

    * Learn typical MVPA approaches (correlation analysis, classification analysis, representational similarity analysis).
    * Learn how these approaches can be applied to both fMRI and MEEG data.
    * Learn how to use CoSMoMVPA to perform these analyses:
        - Understand the dataset structure to represent both the data itself (e.g. raw measurements or summary statistics) and its attributes (e.g. labels of conditions (*targets*), data acquisition run (*chunks*).
        - See how parts of the data can be selected using *slicing* and *splitting*, and combined using *stacking*.
        - Introduce *measures* that compute summaries of the data (such as correlation differences, classification accuracies, similarity to an *a prior* defined representational simillarity matrix) that can be applied to both a single ROI or in a searchlight.
    * Learn multiple-comparison approaches.
    * Make yourself an independent user, so that you can apply the techniques learnt here to your own datasets.

Not covered in this course
--------------------------

    * Preprocessing of fMRI / MEEG  data
    * Learning to use Matlab / Octave
    * Dataset types other than volumetric fMRI data and MEEG time-locked data. (Not covered: surface-based fMRI, source-space MEEG)
    * How to become a CoSMoMVPA developer

Datasets
++++++++

AK6 dataset
-----------
This dataset is used for exercises shown on the website (with answers), and you can use it to learn MVPA. It contains preprocessed data for 8 subjects from :cite:`CGG+12`. In this experiment, participants were presented with categories of six animals: 2 primates: monkeys and lemurs; 2 birds: mallard ducks and yellow-throated warblers; and 2 bugs: ladybugs and luna moths.

Download link: `tutorial data with AK6 data only <datadb-ak6-v0.3.zip>`_

.. image:: _static/fmri_design.png
    :width: 400px

For each participant, the following data is present in the ``ak6`` (for Animal Kingdom, 6 species) directory::

    - s0[1-8]/                  This directory contains fMRI data from 8 of the 12
                                participants studied in the experiment reported in
                                Connolly et al. 2012 (Code-named 'AK6' for animal
                                kingdom, 6-species). Each subject's subdirectory
                                contains the following data:
       - glm_T_stats_perrun.nii A 60-volume file of EPI-data preprocessed using
                                AFNI up to and including fitting a general linear
                                model using 3dDeconvolve. Each volume contains the
                                t-statistics for the estimated response to a one
                                of the 6 stimulus categories. These estimates were
                                calculated independently for each of the 10 runs
                                in the experiment.
       - glm_T_stats_even.nii   Data derived from glm_T_stats_perrun.nii.
       - glm_T_stats_odd.nii    Each is a 6-volume file with the T-values averaged
                                across even and odd runs for each category.
       - brain.nii              Skull-stripped T1-weighted anatomical brain image.
       - brain_mask.nii         Whole-brain mask in EPI-space/resolution.
       - vt_mask.nii            Bilateral ventral temporal cortex mask similar to
                                that used in Connolly et al. 2012.
       - ev_mask.nii            Bilateral early visual cortex mask.


Also present are model similarity structures, which you can see here:

.. image:: _static/sim_sl.png
    :width: 600px

This data is stored in the ``models`` directory::

    - models
       - behav_sim.mat          Matlab file with behavioural similarity ratings.
       - v1_model.mat           Matlab file with similarity values based on
                                low-level visual properties of the stimuli.


MEG obj6 dataset
----------------
This dataset is used for both the tutorial and for the assignments.

It contains MEG data from a single participant viewing images of six categories; for details see the README file.

Download link: `tutorial data with MEEG obj6 data only <datadb-meg_obj6-v0.3.zip>`_.




Tentative schedule
++++++++++++++++++

Dates: Monday 20 June and Tuesday 21 June, 2016.

Location: FBK - POVO, Via Sommarive, 18, 38123 Trento. Room *Sala consiglio* (*Tutorial 3*).

The following schedule is tentative and can change any moment depending on user, organizer and/or presenter needs.

============== ===================================================================================================
Date and time  Description
============== ===================================================================================================
Mo  9:00-10:20 General introduction presentation
-------------- ---------------------------------------------------------------------------------------------------
Mo 10:20-10:40 Coffee break
-------------- ---------------------------------------------------------------------------------------------------
Mo 10:40-12:30 :doc:`get_started` / :doc:`download`; :doc:`ex_dataset_basics`
-------------- ---------------------------------------------------------------------------------------------------
Mo 12:30-13:30 Lunch break
-------------- ---------------------------------------------------------------------------------------------------
Mo 13:30-15:00 :doc:`ex_splithalf_correlations`
-------------- ---------------------------------------------------------------------------------------------------
Mo 15:00-15:30 Coffee break
-------------- ---------------------------------------------------------------------------------------------------
Mo 15:30-16:30 :doc:`ex_classify_lda`,
-------------- ---------------------------------------------------------------------------------------------------
Tu  9:00-10:30 :doc:`ex_measures`; :doc:`ex_neighborhood`
-------------- ---------------------------------------------------------------------------------------------------
Tu 10:30-11:00 Coffee break
-------------- ---------------------------------------------------------------------------------------------------
Tu 11:00-12:30 :doc:`ex_searchlight_measure`; :doc:`ex_meeg_searchlight`
-------------- ---------------------------------------------------------------------------------------------------
Tu 12:30-13:30 Lunch break
-------------- ---------------------------------------------------------------------------------------------------
Tu 13:30-15:00 :doc:`ex_meeg_time_generalization`; :doc:`ex_rsa_tutorial`
-------------- ---------------------------------------------------------------------------------------------------
Tu 15:00-15:30 Coffee break
-------------- ---------------------------------------------------------------------------------------------------
Tu 15:30-16:30  :doc:`ex_multiple_comparisons`; concluding remarks
============== ===================================================================================================


Contact
+++++++
Please send an email to a@b, a=nikolaas.oosterhof, b=unitn.it.

:ref:`Back to index <prni2016>`

.. include:: links.txt
