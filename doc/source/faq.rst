.. _faq:

--------------------------------------
Frequently Asked/Anticipated Questions
--------------------------------------
**What is the history of CoSMoMVPA?**

    CoSMoMVPA was started when Gunnar Blohm and Sara Fabri invited the developers (ACC and NNO) to speak at the *2013 Summer School in Computational Sensory-Motor Neuroscience* ( `CoSMo 2013 workshop`_ ) about multivariate pattern analysis methods.

    In a few days they wrote the basic functionality including the dataset structure (inspired by PyMVPA_), basic input/output support for the NIFTI format, correlation analysis, several classifiers, cross-validation, and representational similarity analysis. They also decided to use restructured text to build a website, and wrote a custom build script to generate documentation for the website, including multiple versions of Matlab files to generate both exercises files (with some code to be filled in) and solution files (with all the code).

    Their plan was to let participants write a basic MVPA toolbox in two days (see the :ref:`exercises <cosmo2013>`). This was, with hindsight, a tad ambitious.

    The initial components in CoSMoMVPA_ still stand, but quite a few things have changed in the meantime. CoSMoMVPA has added support for various file formats, including surface-based data and MEEG data. It also supports a wider range of analyses. Finally, there is a new set of :ref:`exercises <cimec2014>`, less aimed at writing your own toolbox, but more at understanding and implementing basic MVPA techniques using CoSMoMVPA_.

**What, yet another MVPA toolbox? How is this toolbox different from others?**
    Indeed, another MVPA toolbox, featuring:

    + *Simple*, *light-weight*, and *modular* Matlab_ / Octave_ functions .
    + Provides implementations of *all common MVPA analyses* for (correlations, representational similarity, classifiers, crossvalidation, searchlight analysis).
    + Supports volumetric fMRI, surface-based fMRI, and MEEG data alike.
    + Provides :ref:`searchlight <cosmo_searchlight>` functionality for :ref:`volumetric <demo_fmri_searchlight_lda>`, :ref:`surface-based <demo_surface_searchlight_lda>`, MEEG :ref:`time-locked <demo_meeg_timelock_searchlight>`, and :ref:`time-frequency <demo_meeg_timefreq_searchlight>` data.
    + Supports measuring :ref:`generalization over time <demo_meeg_timeseries_generalization>` (or any other dimension), either in an ROI or through a searchlight.
    + Support a variety of formats:

        * fMRI volumetric (:ref:`cosmo_fmri_dataset` and :ref:`cosmo_map2fmri`): AFNI_, BrainVoyager_, ANALYZE, NIFTI_. It can also load ``SPM.mat`` files from SPM_.
        * fMRI surface-based (:ref:`cosmo_surface_dataset` and :ref:`cosmo_map2surface`): Brainvoyager, AFNI (NIML).
        * MEEG (:ref:`cosmo_meeg_dataset` and :ref:`cosmo_map2meeg`): Fieldtrip, EEGLab.

    + Provides proper cluster-based :ref:`multiple comparison correction functionality <cosmo_montecarlo_cluster_stat>` (:ref:`example <demo_surface_tfce>`), using either Threshold-Free Cluster Enhancement or traditional cluster-size based Monte Carlo simulations.
    + Runs on both Matlab_ and GNU Octave_.
    + Various runnable :ref:`example scripts <contents_demo.rst>` and :ref:`exerices <cimec2014>`, describing both on how to perform certain types of analyses (i.e., from a user perspective), and on how typical MVP analyses can be implemented (from a programmer persective).

    For comparison, here is a list of other MVPA toolboxes:

    + PyMVPA_ is implemented in Python (it provided inspiration for the dataset structure and semantics). Our toolbox implements the most commonly used MVP analyses (but not all of them) in Matlab. Those who are familiar with Matlab but not with Python may find CoSMoMVPA easier to use.
    + PRoNTo_ is another Matlab MVPA toolbox, that is much wider in scope and provies a Graphical User Interface. In contrast, our toolbox is more aimed on the analysis itself rather than providing a GUI, meaning it has much fewer lines of code and is simpler in design. This may make it easier to understand its functions, and to modify.
    + Searchmight_ is aimed at searchlight analyses (and does these very fast). CoSMoMVPA does support such analyses (:ref:`example <demo_fmri_searchlight_naive_bayes>`, but also supports other types of analyses not covered by Searchmight.
    + `Princeton MVPA`_ toolbox is a sophisticated toolbox but (we think) harder to use, and is currently not under active development.


**What does CoSMoMVPA *not* provide?**
    It does not provide (and probably never will):

    + Preprocessing of data. For fMRI data it assumed that the data has been preprocessed and, in most use-case scenarios, has been analyzed using the General Linear Model.
    + Implementations of complicated analyses (such as hyperalignment, nested cross validation, recursive feature elimination). If you want to do these, consider using PyMVPA_.
    + A Graphical User Interface (GUI). First, it's a lot of work to build such a thing. Second, writing the code to perform the analyses could be considered as more instructive: it requires one to actually *think* about the analysis, rather than just clicking on buttons.
    + Pretty visualization of fMRI data. Although there is basic functionality for showing slices of fMRI data (through ``cosmo_plot_slices``, for better visualization we suggest to use either your preferred fMRI analysis package, or MRIcron_.

    Also, it does not make coffee for you.

**Does it integrate with PyMVPA?**
    Yes. Dataset structures are pretty much identical in CoSMoMVPA_ (PyMVPA_ provided inspiration for the data structures). The ``mvpa2/datasets/cosmo.py`` module in PyMVPA_ provides input and output support between CoSMoMVPA and PyMVPA datasets and neighborhoods. This means that, for example, searchlights defined in CoSMoMVPA can be run in PyMVPA (possibly benefitting from its multi-threaded implementation), and the results converted back to CoSMoMVPA format.

**Does it run on Octave?**
    Allmost all functionality runs in Octave_, including unit tests through MOxUnit_, but there may be parts that function not so well:

        - Unit tests require MOxUnit_ (because xUnit_ uses object-oriented features not supported by Octave_), and doc-tests are not supported in MOxUnit_ (because Octave_ does not provide ``evalc_``.
        - Support of visualization of MEEG results in FieldTrip_ is limited, because FieldTrip_ provided limited Octave_ compatibility.
        - BrainVoyager_ support through NeuroElf_ is not supported, because NeuroElf_ uses object-oriented features not supported by Octave_.


**How fast does it run?**
    CoSMoMVPA_ is not a speed monster, but on our hardware (Macbook Pro early 2012) a searchlight using typical fMRI data takes one minute for simple analyses (correlation split-half), and a few minutes for more advanced analyses (classifier with cross-validation). Analyses on regions of interest are typically completed in seconds.

**What should I use as input for MVPA?**
    We suggest the following:

    * fMRI options:

        - Apply the GLM for each run seperately, with separate predictors for each condition. Each run is a chunk, and each experimental condition is a target. You can use either beta estimates or t-statistics.
        - Split the data in halves (even and odd) and apply the GLM to each of these (i.e. treat the experiment as consisting of two 'runs'). In this case there are two chunks, and the same number of unique targets as there are experimental conditions.

    * MEEG options:

        - Assign chunks based on the run number
        - If the data in different trials in the same run can be assumed to be independent, use unique chunk values for each trial. If that gives you a lot of chunks (which makes crossvalidation slow), use :ref:`cosmo_chunkize`.

**Who are the developers of CoSMoMVPA?**
    Currently the developers are Nikolaas N. Oosterhof and Andrew C. Connolly. In the code you may find their initials (``NNO``, ``ACC``) in commented header sections.

**Which classifiers are available?**
    + Naive Bayes (:ref:`cosmo_classify_naive_bayes`).
    + Nearest neighbor (:ref:`cosmo_classify_nn`).
    + k-nearest neighbor (:ref:`cosmo_classify_knn`).
    + Support Vector Machine (:ref:`cosmo_classify_svm`; requires the Matlab ``stats`` or ``bioinfo`` toolbox, or LIBSVM_).
    + Linear Discriminant Analysis (:ref:`cosmo_classify_lda`).

**Which platforms does it support?**
    It has been tested with Windows, Mac and Linux.

**What future features can be expected?**
    Time permitting, there are some features that may be added in the future:

    + MEEG source analysis support.
    + Snippets of useful code no the website.

**How can I contact the developers?**
    Please send an email to a@c or b@d, where a=andrew.c.connolly, b=nikolaas.oosterhof, c=dartmouth.edu, d=unitn.it.

**Is there a mailinglist?**
    There is the `CoSMoMVPA Google group`_.

===================
Technical questions
===================

**How do I ...**

.. contents::
    :local:
    :depth: 1

Find the correspondence between voxel indices in AFNI and feature indices in CoSMoMVPA
--------------------------------------------------------------------------------------


    In the AFNI GUI, you can view voxel indices by right-clicking on the coordinate field in the very right-top corner. Note that:

        - ds.fa.i, ds.fa.j, and ds.fa.k are base-1 whereas AFNI uses base-0. So, to convert AFNI's ijk-indices to CoSMoMVPA's, add 1 to AFNI's coordinates.
        - CoSMoMVPA's coordinates are valid for LPI-orientations, but not for others. To convert a dataset to LPI, do: 3dresample -orient LPI -inset my_data+orig -prefix my_data_lpi+orig.


Get ECoG data in a CoSMoMVPA struct
----------------------------------


        'I have eCog data in a 3D array (``channels x time x trials``). How can I get this in a CoSMoMVPA struct?'

    Let's assume there is data with those characteristics; here we generate synthetic data for illustration. This data has 7 time points, 3 channels, and 10 trials:

        .. code-block:: matlab

            time_axis=-.1:.1:.5;
            channel_axis={'chan1','chan2','chan3'};

            n_trials=10;
            n_time=numel(time_axis);
            n_channels=numel(channel_axis);

            data=randn([n_channels,n_time,n_trials]); % Gaussian random data

    Because in CoSMoMVPA, samples are in the first dimension, the order of the dimensions have to be shifted so that the ``trials`` (samples) dimension comes first:

        .. code-block:: matlab

            data_samples_first_dim=shiftdim(data,2);

    Now the data can be flattened to a CoSMoMVPA data struct with:

        .. code-block:: matlab

            ds=cosmo_flatten(data_samples_first_dim,...
                                {'chan','time'},...
                                {channel_axis,time_axis});

    Combinations of ``chan`` and ``time`` are the features of the dataset. For example, to see how informative the data is for different time points (across all channels), one could define a :ref:`cosmo_interval_neighborhood` for the time dimension and run a :ref:`searchlight <cosmo_searchlight>`.

    If one would only want to consider the ``chan`` dimension as features, and consider ``time`` as a sample dimension, do:

        .. code-block:: matlab

            ds_time_in_sample_dim=cosmo_dim_transpose(ds,{'time'},1);

    When the data is in this form, one can analyse how well information :ref:`generalizes over time <demo_meeg_timeseries_generalization>` .

Run group analysis
------------------


        'I ran an fMRI searchlight analysis using :ref:`cosmo_searchlight` with :ref:`cosmo_spherical_neighborhood` and got a result map for a single participant. Now I want to repeat this for my other participants, and then do a group analysis. It is my understanding that I should use :ref:`cosmo_montecarlo_cluster_stat`, but the documentation refers to :ref:`cosmo_cluster_neighborhood`.'

    Indeed :ref:`cosmo_cluster_neighborhood` should be used with :ref:`cosmo_montecarlo_cluster_stat`, because that neighborhood function returns a neighborhood structure indicating which features (voxels) are next to each other. This is different from, say, a spherical neighborhood with a radius of 3 voxels.

        (Technically :ref:`cosmo_cluster_neighborhood`, when applied on a typical fMRI dataset (that is, without other feature dimensions), returns by default a neighborhood that is equivalent to a spherical neighborhood with a radius between ``sqrt(3)`` and ``2``, meaning that under the assumption of isotropocy, voxels are neighbors if they share at least a vertex (corner).

        Also, :ref:`cosmo_cluster_neighborhood` works on other types of datasets, including surface-based fMRI, timelocked MEEG, and time-frequency MEEG.)

    First of all, it is important that subjects are in the same common space, such as MNI or Talairach.
    If you run the searchlight for each subject along the following lines:

        .. code-block:: matlab

            result_cell=cell(nsubj,1);
            for subj=1:nsubj
                % searchlight code for this subject
                % (your code here)
                result=searchlight(...);

                % here we assume a single output (sample) for each
                % searchlight. For statistical analysis later, where
                % we want to do a one-sample t-test, we set
                % .sa.targets to 1 (any constant value will do) and
                % .sa.chunks to the subject number.
                % nsamples=size(result.samples,1);
                %
                % Notes:
                % - these values can also be set after the analysis is run,
                %   although that may be more error-prone
                % - for other statistical tests, such as one-way ANOVA,
                %   repeated-measures ANOVA, paired-sample t-test and
                %   two-sample t-tests, chunks and targets have to be
                %   set differently. See the documentation of
                %   cosmo_montecarlo_cluster_stat for details.

                result.sa.targets=1;
                result.sa.chunks=subj;
                result_cell{subj}=result;
            end

    then data can be joined using

        .. code-block:: matlab

            result=cosmo_stack(result_cell);

    (If this gives an error because feature attributes do not match: this can be due to using different brain masks across participants. To use a common mask, either use :ref:`cosmo_fmri_dataset` with a common mask to load the data before running the searchlight, or apply a common mask afterwards, as in

        .. code-block:: matlab

            % If data from different subjects was based on different masks,
            % they can be masked afterwards using a common mask.
            %
            % It is strongly recommended to use a the common mask that
            % is an intersection mask, with non-zero values only for features
            % (voxels) that have data for all participants. Otherwise
            % this could lead to either loss of power, or (in the case
            % of the 'h0_mean' parameter set to a non-zero value in
            % cosmo_montecarlo_cluster_stat), incorrect results with
            % artifacts


            % for the common mask use either a filename, or a dataset with
            % a single sample
            common_mask='my_common_mask.nii';

            for k=1:nsubj
                % apply common mask for each subject
                result_cell{k}=cosmo_fmri_dataset(result_cell{k},...
                                        'mask',common_mask);
            end

    Assuming that ``result`` was constructed as above, a group analysis using Threshold-Free Cluster Enhancement and using 1000 permutations can now by done quite easily. For a one-sample t-test (one sample per participant, it is however required to specify the mean under the null hypothesis. When the :ref:`cosmo_correlation_measure` or :ref:`cosmo_target_dsm_corr_measure` is used, this is typically zero, whereas for :ref:`cosmo_crossvalidation_measure`, this is typically 1 divided by the number of classes (e.g. ``0.25`` for 4-class discrimination).

        .. code-block:: matlab

            % one-sample t-test against 0
            % (for representational similarity analysis)
            h0_mean=0;

            % number of null iterations.
            % values of at least 10,000 are recommended for publication-quality
            niter=1000;

            %
            % Set neighborhood for clustering
            cluster_nbrhood=cosmo_cluster_neighborhood(result);

            stat_map=cosmo_montecarlo_cluster_stat(result, cluster_nbrhood,...
                                                    'niter', niter,...
                                                    'h0_mean', h0_mean);





    .. include:: links.txt
