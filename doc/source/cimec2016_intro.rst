.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. intro

*Note: This page describes the first part of the course, between 6 April and 2 May 2016. The second part of the course, between 4 May and 11 May 2016, is taught by Christoph Braun and will cover analysis of MEEG data. Information about the second part is not presented here.*

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

Download link: `tutorial data with AK6 data only <datadb-ak6.zip>`_

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
This dataset is used for assignments which will count towards the student's grade for the course.

It contains data from five participants in the original study by Haxby et al (:cite:`HGF+01`); for details see the README file.

Download link: `Haxby 2001 et al data GLM data <haxby2001-glm-v0.1.zip>`_


Links
-----
Official website: http://cosmomvpa.org. This is the up-to-date authoritative source.

Internal backup mirror (CIMeC-only): http://mat-storage-weisz.unitn.it/cosmomvpa/. This website may be out of date, but should be used for downloading example data.

Assignments
+++++++++++

In the first four weeks we plan one assignment per week. In addition, one assignment after classes have ended *may* be added. Each assignment will involve MVPA using CoSMoMVPA. More details about assignments will be added here soon.

Notes:

- You can use PyMVPA for all fMRI exercises (instead of CoSMoMVPA), but you will be more or less on your own; PyMVPA is not part of the course.
- Using PyMVPA for the MEEG exercises is currently rather challening, as there is little support for MEEG in PyMVPA.

Preparation
-----------
- Download the Haxby2001 GLM dataset and store it at a location of your preference
- Update your ``.cosmomvpa.cfg`` file, so that it contains a new line with a ``haxby2001_data_path`` key; for example the contents could be as follows:

        .. code-block:: none

            tutorial_data_path=/Users/karen/datasets/CoSMoMVPA/datadb/tutorial_data
            output_data_path=/Users/karen/tmp/CoSMoMVPA_output
            haxby2001_data_path=/Users/karen/datasets/CoSMoMVPA/haxby2001-glm-v0.1


Format
------

Please write a matlab ``.m`` file that can be executed. Use the following as a template for the beginning of the file:

    .. code-block:: matlab

        % CIMEC 2016 hands-on method class
        % Assignment 1
        %
        % Name:           karen
        % Student number: 654321
        % Email address:  karen@studenti.unitn.it
        % Date:           08 Apr 2016

        config=cosmo_config();
        data_path=config.haxby2001_data_path;


so that your solution can be run on other computers where the data is stored in a different directory.

Your solution will be rated not only on correctness and completeness of the implementation, but also on readibility and understandibility. Please indent your code, add comments where necessary, and use reasonable variable names. For details, see :ref:`matlab code guidelines`.

You should write your own code and comments. It is acceptable to use code from the CoSMoMVPA website, the CoSMoMVPA code-base, or from other internet sources, but please indicate (through comments in the code) if and where you have used code from elsewhere. It is also acceptable to discuss the problem with your fellow students. It is not acceptable to copy code from your fellow students.

Please send your solution before the deadline to James Haxby and Nikolaas Oosterhof, and use the subject line ``CIMEC hands-on - exercise X``, with ``X`` the appropriate value.

Exercise 1 - deadline 23:59, 19 April 2016
------------------------------------------
Use the Haxby 2001 GLM dataset (see above) for the following analyses:

- single subject pattern similarity visualization. Load GLM data from subject ``s01`` from two thirds of the data, ``glm_t1_8cond-tstat.nii`` and ``glm_t2_8cond-tstat.nii``. Use the ``vt`` mask and load the data for eight conditions from these two halves. Now compute all ``8 * 8 = 64`` pair-wise correlations of the patterns across the first and second half. Quantify the presence of reliable patterns through a *split-half information score* that discriminates between conditiosn by computing the average on-diagonal values minus the average of the off-diagonal values in the correlation matrix. Visualize the correlations using ``imagesc``. (Note: since the single subject results are not very strong, do not worry if the matrix does not show clearly higher values on the diagonal than off the diagonal)

    Suggested functions:

    - :ref:`cosmo_fmri_dataset`
    - ``corr`` / :ref:`cosmo_corr` (or :ref:`cosmo_correlation_measure`)
    - ``mean``
    - ``imagesc``

- single subject significance testing. Using the data loaded for subject ``s01`` as described above, estimate how significant the *split-half correlation score* is different from zero. Generate a null dataset by reshuffling the labels in one half of the data, and then compute the *split-half correlation score* for this null dataset. Using a ``for``-loop, repeat this process 1000 times (i.e., use 1000 iterations) to get 1000 split-half null data correlation scores. Finally, compute the significance of the original split-half correlation score by dividing the number of times the original split-half correlation score is less than the null-data correlation scores by the number of iterations (1000). Show a histogram with the 1000 null data correlation scores, and a vertical line showing the correlation score in the original data.

    Suggested functions:

    - ``randperm`` (or :ref:`cosmo_randomize_targets`)
    - ``hist``

- group analysis. Load the same data as in the single subject analysis, but now for each of the five participants. Do a group analysis in areas ``vt`` and ``ev`` using a one-sample t-test to estimate how reliable the split-half correlation score is different from zero across the five participants.

    Suggested functions:

    - ``ttest`` (or :ref:`cosmo_stat`)


Exercise 2 - deadline 23:59, 26 April 2016
------------------------------------------
Use the Haxby 2001 GLM dataset (see above) for the following analyses:

- *Single subject pattern classification*. Load data from each run for each of the eight conditions ``glm_t12-perrun_8cond-tstat.nii``. Using take-one-run-out cross-validation, use both the LDA and NN classifier to compute classificationa accuracies in the ``vt`` region. Do the same for the ``ev`` region. Compute classification accuracies and show classification confusion matrices for each of the two ROIs and each of the classifiers.

    Suggested functions:

    - :ref:`cosmo_classify_lda`, :ref:`cosmo_classify_nn`
    - (Optional) :ref:`cosmo_confusion_matrix`.
    - (Optional) :ref:`cosmo_crossvalidation_measure`.
    - (Optional) :ref:`cosmo_nfold_partitioner`.
    - ``imagesc``.


- *Custom classifier*. Implement a maximum correlation classifier (c.f. :cite:`HGF+01`). Given a test pattern, the maximum correlation classifier should return the class corresponding to the train patterns that has the highest (Pearson) correlation with the test pattern. Then use it to classify patterns of the eight categories using the ``glm_t12-perrun_8cond-tstat.nii`` data in the ``vt`` region. Your solution should start as follows:

    .. code-block:: matlab

        function pred=my_corr_classify(samples_train,targets_train,samples_test,opt)
        % maximum correlation classifier
        %
        %   predicted=my_max_corr_classify(samples_train, targets_train, samples_test[,opt])
        %
        %   Inputs:
        %     samples_train       PxR training data for P samples and R features
        %     targets_train       Px1 training data classes
        %     samples_test        QxR test data
        %     opt                 Optional struct, unused.
        %
        %   Output:
        %     predicted           Qx1 predicted data classes for samples_test. For
        %                         all values of k in the range (1:Q):
        %                           if r is the row for which tr_samples(r,:) shows
        %                           the highest with samples_train(k,:), then
        %                           pred(k)==targets_train(r)
        %


            [nsamples_train, nfeatures]=size(samples_train);
            [ntargets, one_check]=size(targets_train);
            [nsamples_test, nfeatures_check]=size(te_samples);

            if nsamples_train~=ntargets
                error('Samples (%d) and targets (%d) size mismatch',...
                            nsamples_train, ntargets);
            end

            if one_check~=1
                error('targets must be a column vector');
            end

            if nfeatures~=nfeatures_check
                error('feature count mismatch in train (%d) and test (%d) set',...
                        nfeatures, nfeatures_check);
            end

            %%%% Your code comes here %%%%

    Suggested functions:

    - ``corr`` (or :ref:`cosmo_corr`)

- *Group analysis*. Load the same data as in the single subject analysis, but now for each of the five participants. Using the LDA classifier, do a group analysis in areas ``vt`` and ``ev`` using a one-sample t-test to estimate how reliable classification accuracies are different from chance level (``1/8``) across the five participants.

  Suggested functions:

    - ``ttest`` (or :ref:`cosmo_stat`)



FAQ
+++

- For the assignments, can I use / adapt existing CoSMoMVPA code from the exercises or demonstrations?

    * yes, as long as you indicate that you took the code from elsewhere, and indicate where you took it from.

- Are there slides available?

    * currently not; we try to provide all information on the website.

Tentative schedule
++++++++++++++++++

Location: Pallazina Fedrigotti, computer room at the ground floor.

The following schedule is tentative and can change any moment depending on student and/or presenter needs.

========= =========== ===================================================================================================
Date      Time        Description
========= =========== ===================================================================================================
We  6 Apr 09:00-10:45 General intro: Get your computer ready to run CoSMoMVPA and use the tutorial dataset
--------- ----------- ---------------------------------------------------------------------------------------------------
Th  7 Apr 14:00-15:45 Practical exercises: Basic dataset operations
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr  8 Apr 14:00-15:45 Practical exercises: Basic dataset operations, split-half correlation analysis
--------- ----------- ---------------------------------------------------------------------------------------------------
We 13 Apr 09:00-10:45 Practical exercises: Split-half correlation analysis
--------- ----------- ---------------------------------------------------------------------------------------------------
Th 14 Apr 14:00-15:45 Practical exercises: Split-half correlation analysis, single-fold classification
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr 15 Apr 14:00-15:45 Practical exercises: Classification with cross-validation
--------- ----------- ---------------------------------------------------------------------------------------------------
We 20 Apr 09:00-10:45 Practical exercises: Measures, neighborhoods, searchlight
--------- ----------- ---------------------------------------------------------------------------------------------------
Th 21 Apr 14:00-15:45 Practical exercises: Basic RSA
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr 22 Apr 14:00-15:45 Practical exercises: Basic RSA, searchlight RSA
--------- ----------- ---------------------------------------------------------------------------------------------------
Tu 26 Apr 14:00-15:45 Practical exercises: MEEG classification, searchlights
--------- ----------- ---------------------------------------------------------------------------------------------------
We 27 Apr 09:00-10:45 Practical exercises: MEEG time generalization
--------- ----------- ---------------------------------------------------------------------------------------------------
Mo 02 May 14:00-15:45 Concluding remarks
--------- ----------- ---------------------------------------------------------------------------------------------------
--------- ----------- ---------------------------------------------------------------------------------------------------
We  4 May 09:00-10:45 NA; taught by Christoph Braun
--------- ----------- ---------------------------------------------------------------------------------------------------
Th  5 May 14:00-15:45 NA; taught by Christoph Braun
--------- ----------- ---------------------------------------------------------------------------------------------------
Fr  6 May 14:00-15:45 NA; taught by Christoph Braun
--------- ----------- ---------------------------------------------------------------------------------------------------
We 11 May 09:00-10:45 NA; taught by Christoph Braun
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
