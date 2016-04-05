.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. intro

*Note: This page describes the first part of the course, between 6 and 29 April 2016. The second part of the course, between 4 May and 11 May 2016, is taught by Christoph Braun and will cover analysis of MEEG data. Information about the second part is not presented here.*


Introduction
============

Prerequisites
+++++++++++++

    * Matlab / Octave :ref:`Advanced beginner level <matlab_experience>`.
    * fMRI analysis :ref:`advanced beginner level <cogneuro_experience>`.
    * Working Matlab_ or Octave_ installation.
    * :ref:`CoSMoMVPA source code and tutorial data <get_code_and_example_data>`.


Goals of the fMRI / MVPA part of the course
+++++++++++++++++++++++++++++++++++++++++++

    * For fMRI data, describe the typical MVPA approaches (correlation analysis, classification analysis, representational similarity analysis) applied to both regions of interest and across the whole brain in a *searchlight* approach.
    * For MEEG data, learn basic spatio-temporal MVPA approaches.
    * If necessary, learn enough Matlab to use CoSMoMVPA.
    * Learn how to use CoSMoMVPA to perform these analyses:
        - Understand the dataset structure to represent both the data itself (e.g. raw measurements or summary statistics) and its attributes (e.g. labels of conditions (*targets*), data acquisition run (*chunks*).
        - See how parts of the data can be selected using *slicing* and *splitting*, and combined using *stacking*.
        - Introduce *measures* that compute summaries of the data (such as correlation differences, classification accuracies, similarity to an *a prior* defined representational simillarity matrix) that can be applied to both a single ROI or in a searchlight.
    * Make yourself an independent user, so that you can apply the techniques learnt here to your own datasets.


Not covered in this course
--------------------------

    * Preprocessing of fMRI or MEEG data
    * Advanced topics in Matlab / GNU Octave
    * Connectivity analysis
    * How to become a CoSMoMVPA developer

Sample Datasets
+++++++++++++++

AK6 dataset
-----------
This dataset is used for exercises shown on the website (with answers), and you can use it to learn MVPA. It contains preprocessed data for 8 subjects from :cite:`CGG+12`. In this experiment, participants were presented with categories of six animals: 2 primates: monkeys and lemurs; 2 birds: mallard ducks and yellow-throated warblers; and 2 bugs: ladybugs and luna moths.

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


Haxby2001 dataset
-----------------
This dataset is used for assignments which will count towards the student's grade for the course. More information will be added soon.

Links
-----
Official website: http://cosmomvpa.org

Internal backup mirror (CIMeC-only): http://mat-storage-weisz.unitn.it/cosmomvpa/


Assignments
+++++++++++

In the first four weeks we plan one assignment per week. Each assignment will involve MVPA using CoSMoMVPA.
More details about assignments will be added here soon.

Note: you can use PyMVPA for all fMRI exercises (instead of CoSMoMVPA), but you will be on your own. PyMVPA is not part of the course.
Using PyMVPA for the MEEG exercises is currently not possible.

Tentative schedule
++++++++++++++++++

Location: Pallazina Fedrigotti, computer room at the ground floor.

The following schedule is tentative and can change any moment depending on student and/or presenter needs.

========= =========== ===================================================================================================
Date      Time        Description
========= =========== ===================================================================================================
We  6 Apr 09:45-11:00 General intro: Get your computer ready to run CoSMoMVPA and use the tutorial dataset
--------- ----------- ---------------------------------------------------------------------------------------------------
Th  7 Apr 14:00-15:45 Practical exercises: Basic dataset operations
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr  8 Apr 14:00-15:45 Practical exercises: Correlation analysis
--------- ----------- ---------------------------------------------------------------------------------------------------
We 13 Apr 09:45-11:00 Practical exercises: Basic classification analysis
--------- ----------- ---------------------------------------------------------------------------------------------------
Th 14 Apr 14:00-15:45 Practical exercises: Classification with cross-validation
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr 15 Apr 14:00-15:45 Practical exercises: Measures, neighborhoods, searchlight
--------- ----------- ---------------------------------------------------------------------------------------------------
We 20 Apr 09:45-11:00 Practical exercises: Basic RSA
--------- ----------- ---------------------------------------------------------------------------------------------------
Th 21 Apr 14:00-15:45 Practical exercises: RSA consistency and visualization
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr 22 Apr 14:00-15:45 Practical exercises: RSA consistency
--------- ----------- ---------------------------------------------------------------------------------------------------
We 27 Apr 09:45-11:00 Practical exercises: MEEG classification, searchlights
--------- ----------- ---------------------------------------------------------------------------------------------------
Th 28 Apr 14:00-15:45 Practical exercises: MEEG time generalization
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr 29 Apr 14:00-15:45 Concluding remarks
--------- ----------- ---------------------------------------------------------------------------------------------------
--------- ----------- ---------------------------------------------------------------------------------------------------
We  4 May 09:45-11:00 NA; taught by Christoph Braun
--------- ----------- ---------------------------------------------------------------------------------------------------
Th  5 May 14:00-15:45 NA; taught by Christoph Braun
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr  6 May 14:00-15:45 NA; taught by Christoph Braun
--------- ----------- ---------------------------------------------------------------------------------------------------
We 11 May 09:45-11:00 NA; taught by Christoph Braun
--------- ----------- ---------------------------------------------------------------------------------------------------
Th 12 May 14:00-15:45 NA; taught by Christoph Braun
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr 13 May 14:00-15:45 NA; taught by Christoph Braun
========= =========== ===================================================================================================

Contact
+++++++
Please send an email to a@c or b@c, a=nikolaas.oosterhof, b=james.haxby, and c=unitn.it.


:ref:`Back to index <cimec2016>`

.. include:: links.txt
