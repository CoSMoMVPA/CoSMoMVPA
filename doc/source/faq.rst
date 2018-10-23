.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _faq:

--------------------------------------
Frequently Asked/Anticipated Questions
--------------------------------------


.. contents::

=======
General
=======

.. _how_to_cite:

How should I cite CoSMoMVPA?
----------------------------
Please cite :cite:`OCH16`:

    Oosterhof, N. N., Connolly, A. C., and Haxby, J. V. (2016). CoSMoMVPA: multi-modal multivariate pattern analysis of neuroimaging data in Matlab / GNU Octave. Frontiers in Neuroinformatics, :doi:`10.3389/fninf.2016.00027`.

BiBTeX record::

    @article{OCH16,
    author = {Oosterhof, Nikolaas N and Connolly, Andrew C and Haxby, James V},
    title = {{CoSMoMVPA: multi-modal multivariate pattern analysis of neuroimaging data in Matlab / GNU Octave}},
    journal = {Frontiers in Neuroinformatics},
    doi = {10.3389/fninf.2016.00027},
    year = {2016}
    }


What is the history of CoSMoMVPA?
---------------------------------

    CoSMoMVPA was started when Gunnar Blohm and Sara Fabri invited the developers (ACC and NNO) to speak at the *2013 Summer School in Computational Sensory-Motor Neuroscience* ( `CoSMo 2013 workshop`_ ) about multivariate pattern analysis methods.

    In a few days they wrote the basic functionality including the dataset structure (inspired by PyMVPA_), basic input/output support for the NIFTI format, correlation analysis, several classifiers, cross-validation, and representational similarity analysis. They also decided to use restructured text to build a website, and wrote a custom build script to generate documentation for the website, including multiple versions of Matlab files to generate both exercises files (with some code to be filled in) and solution files (with all the code).

    Their plan was to let participants write a basic MVPA toolbox in two days (see the :ref:`exercises <cosmo2013>`). This was, with hindsight, a tad ambitious.

    The initial components in CoSMoMVPA_ still stand, but quite a few things have changed in the meantime. CoSMoMVPA has added support for various file formats, including surface-based data and MEEG data. It also supports a wider range of analyses. Finally, there is a new set of :ref:`exercises <rhul2016>`, less aimed at writing your own toolbox, but more at understanding and implementing basic MVPA techniques using CoSMoMVPA_.

    For recent changes, see the :ref:`changelog`.

What are the main features?
---------------------------
CoSMoMVPA_ provides:

    + A simple, yet powerful, :ref:`data structure <cosmomvpa_dataset>` that treats fMRI and MEEG data both as first-class citizens.
    + *Simple*, *light-weight*, and *modular* functions.
    + Implementations of *all common MVPA analyses* through :ref:`measures <cosmomvpa_measure>`, such as:

        - correlation split-half
        - representational similarity
        - crossvalidation with classifiers
        - generalization over time

    + :ref:`Neighborhoods <cosmomvpa_neighborhood>` in various spaces, including

        - volumetric and surface-based (fMRI)
        - time, frequency, sensors, and source elements (MEEG)
        - all combinations of the above, for example:

            + voxel x time (volumetric fMRI)
            + node x time (surface-based fMRI)
            + time x sensor (MEEG)
            + time x frequency x sensor (MEEG)
            + time x source element (MEEG)
            + time x frequency x source element (MEEG)

      where each of the above :ref:`measures  <cosmomvpa_measure>` can be used with a neighborhood to run searchlights in all the above spaces.

    + Support for a wide variety of image formats, including:

        - AFNI_
        - SPM_
        - NIFTI_
        - ANALYZE_
        - BrainVoyager_
        - FieldTrip_
        - EEGLAB_ (ASCII)

    + proper Monte Carlo cluster-based :ref:`multiple comparison correction <cosmo_montecarlo_cluster_stat>` (:ref:`example <demo_surface_tfce>`), using either Threshold-Free Cluster Enhancement or traditional cluster-size based Monte Carlo simulations, in all the supported neighborhood spaces..
    + support for both the Matlab_ and GNU Octave_ platforms.
    + various runnable :ref:`example scripts <contents_demo.rst>` and :ref:`exerices <rhul2016>`, describing both on how to perform certain types of analyses (i.e., from a user perspective), and on how typical MVP analyses can be implemented (from a programmer persective).


What does CoSMoMVPA *not* provide?
----------------------------------
    It does not provide (and probably never will):

    + Preprocessing of data. It assumed that the data has been preprocessed using other packages (such as AFNI, SPM, or FieldTrip for fMRI; EEGLAB or FieldTrip for MEEG). For fMRI analyses, in most use-case scenarios, it may be preferable to use response estimates from a General Linear Model.
    + Implementations of complicated analyses (such as hyperalignment, nested cross validation, recursive feature elimination). If you want to do these, consider using PyMVPA_.
    + A Graphical User Interface (GUI). First, it's a lot of work to build such a thing. Second, writing the code to perform the analyses could be considered as more instructive: it requires one to actually *think* about the analysis, rather than just clicking on buttons.
    + Pretty visualization of fMRI data. Although there is basic functionality for showing slices of fMRI data (through ``cosmo_plot_slices``, for better visualization we suggest to use either your preferred fMRI analysis package, or MRIcron_.

    Also, it does not make coffee for you.

Does it integrate with PyMVPA?
------------------------------
    Yes. Dataset structures are pretty much identical in CoSMoMVPA_ (PyMVPA_ provided inspiration for the data structures). The ``mvpa2/datasets/cosmo.py`` module in PyMVPA_ provides input and output support between CoSMoMVPA and PyMVPA datasets and neighborhoods. This means that, for example, searchlights defined in CoSMoMVPA can be run in PyMVPA (possibly benefitting from its multi-threaded implementation), and the results converted back to CoSMoMVPA format.

Does it run on GNU Octave?
--------------------------
    Almost all functionality runs in Octave_ 3.8, including unit tests through MOxUnit_, but there may be parts that function with limitations:

        - BrainVoyager_ support through NeuroElf_ is not supported, because NeuroElf_ uses object-oriented features not supported by Octave_.



How fast does it run?
-----------------------
    CoSMoMVPA_ is not a speed monster, but on limited hardware a searchlight using typical fMRI data takes one minute for simple analyses (correlation split-half), and a few minutes for more advanced analyses (classifier with cross-validation). The naive Bayes searchlights takes a few seconds for whole-brain fMRI per classification fold. Analyses on regions of interest are typically completed in seconds. Certain analysed (searchlight, multiple comparison correction) can be parallelized over multiple cores if a supported toolbox is available.

What should I use as input for MVPA?
------------------------------------
    We suggest the following:

    * fMRI options:

        - Apply the GLM for each run seperately, with separate predictors for each condition. Each run is a chunk, and each experimental condition is a target. You can use either beta estimates or t-statistics.
        - Split the data in halves (even and odd) and apply the GLM to each of these (i.e. treat the experiment as consisting of two 'runs'). In this case there are two chunks, and the same number of unique targets as there are experimental conditions.

    * MEEG options:

        - Preprocess the data (e.g. bandpassing, artifact rejection, downsampling).
        - For chunk assignment, either:

            + Assign chunks based on the run number.
            + If the data in different trials in the same run can be assumed to be independent, use unique chunk values for each trial. If that gives you a lot of chunks (which makes crossvalidation slow), use :ref:`cosmo_chunkize`.

Who are the developers of CoSMoMVPA?
------------------------------------
    Currently the developers are Nikolaas N. Oosterhof and Andrew C. Connolly. In the code you may find their initials (``NNO``, ``ACC``) in commented header sections.

Which classifiers are available?
--------------------------------
    + Naive Bayes (:ref:`cosmo_classify_naive_bayes`).
    + Nearest neighbor (:ref:`cosmo_classify_nn`).
    + k-nearest neighbor (:ref:`cosmo_classify_knn`).
    + Support Vector Machine (:ref:`cosmo_classify_svm`); requires the Matlab ``stats`` or ``bioinfo`` toolbox, or LIBSVM_.
    + Linear Discriminant Analysis (:ref:`cosmo_classify_lda`).

Which platforms does it support?
--------------------------------
    It has been tested with Windows, Mac and Linux.

What future features can be expected?
-------------------------------------
    Time permitting, there are some features that may be added in the future:

    + Snippets of useful code on the website.

How can I contact the developers directly?
------------------------------------------
    Please send an email to a@c or b@d, where a=andrew.c.connolly, b=n.n.oosterhof, c=dartmouth.edu, googlemail.com.

Is there a mailinglist?
-----------------------
    There is the `CoSMoMVPA Google group`_.


Why do you encourage balanced partitions?
-----------------------------------------
        'I noticed that CoSMoMVPA heavily 'encourages' balanced class distributions (with equal number of samples in each class), and recommends to remove data to balance; why?'

TL;DR: it's much simpler and you don't lose much by enforcing balanced partitions.

Longer version:the main reason for encouraging (almost enforcing) balanced partitions is a combination of simplicity and avoiding mistakes with 'above chance' classification.
It is considerably simple when chance is 1/c, with c the number of classes; in particular, this simplifies second level (group) analysis and allows for a relatively quick Monte Carlo based multiple-comparison correction through sign-swapping (as implemented in :ref:`cosmo_montecarlo_cluster_stat`).
In addition, most paradigms use quite balanced designs anyway, so you do not loose much trials by enforcing balancing. If not using all trials would be a concern, one can re-use the same samples multiple times in different cross-validation folds through cosmo_balance_partitions with the 'nrepeats' or 'nmin' arguments.



============
How do I ...
============

.. contents::
    :local:
    :depth: 1

Find the correspondence between voxel indices in AFNI and feature indices in CoSMoMVPA
--------------------------------------------------------------------------------------


    In the AFNI GUI, you can view voxel indices by right-clicking on the coordinate field in the very left-top corner. Note that:

        - ``ds.fa.i``, ``ds.fa.j``, and ``ds.fa.k`` are base-``1`` whereas AFNI uses base-``0``. So, to convert AFNI's ``ijk``-indices to CoSMoMVPA's, add ``1`` to AFNI's coordinates.
        - CoSMoMVPA's coordinates are valid for LPI-orientations, meaning that the first dimension is from left (lower values) to right (higher values), the second dimension is from posterior (lower values) to anterior (higher values), and the third dimension from inferior (lower values) to superior (higher values). To convert a dataset to LPI-orientation using AFNI, do:

        .. code-block:: shell

            3dresample -orient LPI -inset my_data+orig -prefix my_data_lpi+orig.

.. _faq_get_ecog_data_in_cosmomvpa_struct:

Get ECoG data in a CoSMoMVPA struct
-----------------------------------


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

Get temporal data in a CoSMoMVPA struct
---------------------------------------

        'Using MEEG dataset, using custom written software I have precomputed RSA correlations across channels for a group of subjects for each timepoints; the result is ``data`` matrix of size ``17x300``, corresponding to ``subjects x time``. How can I get this in a CoSMoMVPA dataset struct, and use :ref:`cosmo_montecarlo_cluster_stat` for multiple comparison correction?'

    We will generate some (random) data with these characteristics:

    .. code-block:: matlab

        % generate pseudo-random data
        data=cosmo_rand(17,300);

        % set the time (in seconds) for each column
        % Here, the first time point is 200ms pre-stimulus
        % and each time step is 2ms. The last time point
        % is at 398 ms
        time_axis=-.2:.002:.398;


    To get the data in a dataset structure, a similar approach is followed as in another FAQ entry (:ref:`faq_get_ecog_data_in_cosmomvpa_struct`) - but note that there is only a time axis here to use as a feature dimension:

    .. code-block:: matlab

        ds=cosmo_flatten(data,{'time'},{time_axis},2)

    Clustering with  :ref:`cosmo_montecarlo_cluster_stat` requires (as usual) a clustering neighborhood computed by :ref:`cosmo_cluster_neighborhood`:

    .. code-block:: matlab

        % cluster neighborhood over time points
        cl_nh=cosmo_cluster_neighborhood(ds);

    To use :ref:`cosmo_montecarlo_cluster_stat`, it is required to set targets and chunks. In this case there is a single sample per subject, which is reflected in ``.sa.targets`` and ``.sa.chunks``.

    .. code-block:: matlab

        n_subjects=size(data,1);
        ds.sa.targets=ones(n_subjects,1);
        ds.sa.chunks=(1:n_subjects)';

    To run  :ref:`cosmo_montecarlo_cluster_stat` it is required to set the number of iterations and (for a one-sample t-test) the expected mean under the null hypothesis.

    .. code-block:: matlab

        opt=struct();

        % use at least 10000 iterations for publication-quality analyses
        opt.niter=10000;

        % expected mean under null hypothesis.
        % For this example (pre-computed RSA correlation values)
        % the expected mean is zero.
        opt.h0_mean=0;

        % compute z-scores after TFCE correction
        tfce_z_ds=cosmo_montecarlo_cluster_stat(ds,cl_nh,opt);

    Note that clusters are computed across the time dimension, so if a cluster survives between (say) 100 and 150 ms, one *cannot* infer that at 100 ms there is significant information present that explains the non-zero correlations. Instead, the inferences can only be made at the cluster level, i.e. there is evidence for significant information at a cluster of time points. To be able to make inferences at the individual time point level, use a cluster neighborhood that does not connect clusters across the time dimension:

    .. code-block:: matlab

        % cluster neighborhood not connecting time points
        cl_nh_not_over_time=cosmo_cluster_neighborhood(ds,'time',false);

    in which case a significant feature at (say) 100 ms can directly be interpreted as evidence for information being present at 100 ms. However, such a test is less sensitive than a neighborhood that connects features across time.


.. _faq_run_group_analysis:

Run group analysis
------------------


        'I ran an fMRI searchlight analysis using :ref:`cosmo_searchlight` with :ref:`cosmo_spherical_neighborhood` and got a result map for a single participant. Now I want to repeat this for my other participants, and then do a group analysis. It is my understanding that I should use :ref:`cosmo_montecarlo_cluster_stat`, but the documentation refers to :ref:`cosmo_cluster_neighborhood`.'

    Indeed :ref:`cosmo_cluster_neighborhood` should be used with :ref:`cosmo_montecarlo_cluster_stat`, because that neighborhood function returns a neighborhood structure indicating which features (voxels) are next to each other. This is different from, say, a spherical neighborhood with a radius of 3 voxels.

        (Technically :ref:`cosmo_cluster_neighborhood`, when applied on a typical fMRI dataset (that is, without other feature dimensions), returns by default a neighborhood that is equivalent to a spherical neighborhood with a radius between ``sqrt(3)`` and ``2``, meaning that under the assumption of isotropocy, voxels are neighbors if they share at least a vertex (corner).

        Also, :ref:`cosmo_cluster_neighborhood` works on other types of datasets, including surface-based fMRI, timelocked MEEG, and time-frequency MEEG.)

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



Make an intersection mask across participants
---------------------------------------------
    'I ran my analysis for multiple participants, each with their own mask. Now I want to do group analysis, but combining the data using :ref:`cosmo_stack` gives an error because feature attributes do not match. How can I combine data across participants?

If ``ds_cell`` is a cell so that ``ds_cell{k}`` contains the dataset from the ``k``-th participant, an intersection (based on features common across participants) can be computed though:

    .. code-block:: matlab

        [idxs,ds_intersect_cell]=cosmo_mask_dim_intersect(ds_cell);

For (second level) group analysis, in general, it is a good idea to assign ``chunks`` (if not done already) and ``targets``. The general approach to setting chunks is by indicating that data from different participants is assumed to be independent; for setting targets, see the help of :ref:`cosmo_stat`:

    .. code-block:: matlab

        n_subjects=numel(ds_intersect_cell);
        for subject_i=1:n_subjects
            % get dataset
            ds=ds_intersect_cell{subject_i];

            % assign chunks
            n_samples=size(ds.samples,1);
            ds.sa.chunks=ones(nsamples,1)*subject_i;

            % assign targets
            % Your code comes here; see cosmo_stat on how to assign
            % targets depending on subsequent analysis
            % (one-sample or two-sample t-test, or one-way or
            % repeated-measures ANOVA).


            % store results
            ds_intersect_cell{subject_i}=ds;
        end


The the resulting datasets can be combined through:

    .. code-block:: matlab

        ds_all=cosmo_stack(ds_intersect_cell,1);

Note: The above line may give an error ``non-unique elements in fa.X``, with ``X`` some feature attribute such as ``center_ids`` or ``radius``. This is to be expected if the datasets are the result from another analysis, such as :ref:`cosmo_searchlight`. In that case, the data can be combined using:

    .. code-block:: matlab

        ds_all=cosmo_stack(ds_intersect_cell,1,'drop_nonunique');

Compute for a group of participants who were scanned with MRI the overlap of their masks
----------------------------------------------------------------------------------------
    'I analyzed data for individual fMRI participants that are all in a common MNI space, but with individual masks. When using :ref:`cosmo_mask_dim_intersect` I seem to lose about a third of the voxels present in each participant. How can I visualize which voxels are not shared across participants?'

The following code illustrates how this can be done, using synthetic data.

    .. code-block:: matlab

        keep_ratio=0.95;
        n_subj=10;

        % simulate data for all subjects with their masks mostly overlapping
        ds_cell=cell(n_subj,1);
        for k=1:n_subj
            ds_full=cosmo_synthetic_dataset('seed',0,'size','big');

            n_features=size(ds_full.samples,2);
            keep=cosmo_randperm(n_features,round(n_features*keep_ratio));
            ds=cosmo_slice(ds_full,keep,2);

            ds_cell{k}=ds;
        end

        % do simple intersection mask
        [idxs,ds_cell_common]=cosmo_mask_dim_intersect(ds_cell);
        ds_common=cosmo_stack(ds_cell_common);

        fprintf('Ratio in common: %d / %d\n',size(ds_common.samples,2),n_features);

        % see how often each voxel was in the mask for each participant
        for k=1:n_subj
            ds_single_volume=cosmo_slice(ds_cell{k},1);
            ds_single_volume.samples(:)=1;
            ni=cosmo_map2fmri(ds_single_volume,'-nii');
            img=ni.img;

            if k==1
                img_sum=zeros(size(img));
            end

            img_sum=img_sum+img;
        end

        % convert to a ratio between 0 and 1 (for each voxel)
        ni.img=img_sum / n_subj;

        % convert to dataset structure
        ds_ratio=cosmo_fmri_dataset(ni);

        % the ds_ratio dataset can be visualized as shown here,
        % or stored to disc using cosmo_map2fmri
        cosmo_plot_slices(ds_ratio)





Run group analysis on time-by-time generalization measures
----------------------------------------------------------
    'I used :ref:`cosmo_dim_generalization_measure` on MEEG data to get time-by-time generalization results. How do I run group analysis with cluster correction (:ref:`cosmo_montecarlo_cluster_stat`) on these?'

    Let's assume the data from all subjects is stored in a cell ``ds_cell``, with ``ds_cell{k}`` is a dataset struct with the output from  :ref:`cosmo_dim_generalization_measure` for the ``k``-th subject. Each dataset has the ``train_time`` and ``test_time`` attribute in the sample dimension, and they have to be moved to the feature dimension to use :ref:`cosmo_montecarlo_cluster_stat`):

        .. code-block:: matlab

            n_subjects=numel(ds_cell);
            ds_cell_tr=cell(n_subjects,1);
            for k=1:n_subjects
                ds_cell_tr{k}=cosmo_dim_transpose(ds_cell{k},...
                                    {'train_time','test_time'},2);
            end

   Then, it is almost always necessary to set the ``.sa.targets`` and ``.sa.chunks`` attributes. The former refers to conditions; the latter to (in this case) the subject. See :ref:`cosmo_montecarlo_cluster_stat` how to define these generally for various tests. In the simple case of a one-sample t-test, these would be set as follows:

        .. code-block:: matlab

            for k=1:n_subjects
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

                ds_cell_tr{k}.sa.chunks=k;  % k-th subject
                ds_cell_tr{k}.sa.targets=1; % all same condition

            end

    and results would be joined into a single dataset by:

        .. code-block:: matlab

            ds_tr=cosmo_stack(ds_cell_tr);

    Now group analysis can proceed using :ref:`cosmo_montecarlo_cluster_stat` as described in faq_run_group_analysis_.

    To convert the output (say ``stat_map``) from  :ref:`cosmo_montecarlo_cluster_stat` to matrix form (time by time), do

        .. code-block:: matlab

            [data, labels, values]=cosmo_unflatten(stat_map,2);
            data_mat=squeeze(data);




Use LIBSVM
----------

    Download LIBSVM_, then in Matlab or Octave, do

         .. code-block:: matlab

            cd libsvm; % change this to the directory where you put LIBSVM
            cd matlab  % go to matlab sub-directory
            make       % compile libsvm mex functions; requires a working compiler
            rmpath(pwd)   % } ensure directory is on top
            addpath(pwd)  % } of the search path

            % verify it worked.
            cosmo_check_external('libsvm'); % should not give an error

    + If the ``make`` command failed, make sure you are in the LIBSVM's ``matlab`` subdirectory, and that you have a working `compiler under Matlab`_ or `compiler under Octave`_.

    + If you want to store the path, you can also do

         .. code-block:: matlab

            savepath

    so that the next time you start Matlab or Octave, the correct path is used.

    Matlab also provides an SVM implementation in the ``stats`` (and possible other) toolboxes, and the naming of the training functions are not compatible with LIBSVM. Thus, you can use either Matlab's SVM or LIBSVM, but not both at the same time. To select which SVM implementation is used, set the Matlab search path so that either LIBSVM is on top (comes earlier; to use LIBSVM) or at the bottom (comes later; to use Matlab's SVM).


.. _compiler under Matlab: http://it.mathworks.com/help/matlab/matlab_external/what-you-need-to-build-mex-files.html
.. _compiler under Octave: https://www.gnu.org/software/octave/doc/interpreter/Getting-Started-with-Mex_002dFiles.html


Use surface-based mapping with a low-resolution output surface
--------------------------------------------------------------
The typical use case scenarion is using FreeSurfer_ pial and white matter surfaces that are resampled to standard topology using MapIcosahedron. Then, the high-resolution surfaces are used to define which voxels are associated with each searchlight, whereas the low-resolution surface is used as centers for the searchlight. The former aims to result in more precise selection of voxels; the latter in fewer centers, and thus reduced execution time for the searchlight.

In this scenario, it is required that the vertices in low-resolution surface are a subset of the pair-wise averages of vertices in the high-resolution pial and white surfaces. A typical use case is using standard topologies from AFNI's MapIcosahedron, where the high resolution surfaces are constructed using X linear divisionsof the triangles of an icosahedron, the low-resolution surface is constructed with Y linear divisions, and Y<X and X is an integer multiple of Y.

The pymvpa2-prep-afni-surf_ script (part of PyMVPA_, which is required to run it) provides exactly this functionality. It will resample the surfaces to various resolutions, ranging from 4 linear divisions (162 nodes per hemisphere) to 128 linear divisions (163842 nodes per hemisphere) in steps of powers of two. It will also generate intermediate surfaces (pair-wise avarages of the nodes of the pial and white matter surfaes), and merge left (``lh``) and right (``rh``) hemisphere into a single hemisphere (``mh``). The merged surfaces have the advantages that the searchlight has to be run only once to get results for both hemispheres.


.. _pymvpa2-prep-afni-surf: https://github.com/PyMVPA/PyMVPA/blob/master/bin/pymvpa2-prep-afni-surf


Correct for multiple comparisons
--------------------------------
For second level (group analysis), :ref:`cosmo_montecarlo_cluster_stat` provides cluster-based correction.

There are three *components* in this, and they can be crossed arbitrarily:

    1) clustering method: either ‘standard’ fixed-uncorrected thresholding, or using Threshold-Free Cluster Enhancement (TFCE). The latter is the default in CoSMoMVPA, as it has been proposed it has several advantages (Nichols & Smith, 2009, Neuroimage), including:
        - "TFCE gives generally better sensitivity than other methods over a wide range of test signal shapes and SNR values".
        - avoids "the need to define the initial cluster-forming threshold (e.g., threshold the raw t-statistic image at t>2.5)".
        - avoids the issue that "initial hard thresholding introduces instability in the overall processing chain; small variations in the data around the threshold level can have a large effect on the final output."
        - deals properly with different smoothing levels of the data.
        - makes it easier to "directly interpret the meaning of (what may ideally be) separable sub-clusters or local maxima within very extended clusters".
        - is less affected by nonstationarity.

    2) support for any type of modality that CoSMoMVPA supports, including:

        - fMRI volumetric, e.g. voxel, or voxel x time
        - fMRI surface-based, e.g. node, or node x time
        - MEEG time x channel (both in sensor and source space)
        - MEEG time x channel x frequency (both in sensor and source space)

        In the case of multiple dimensions (such as time x channel x frequency) it is possible to cluster only over a subset of the dimensions. For example, a time x channel x frequency dataset can be clustered over all dimensions, or clustered over channel x frequency (which allows for more precise temporal inferences), or over channel x time (for more precise frequency inferences).

    3) support for either standard permutation test, or the method by Stelzer et al. (2012). To use the Stelzer approach, the user has to generate null datasets themselves. :ref:`cosmo_randomize_targets` can be used for this, but requires using a for-loop to generate multiple null datasets.

Because components 1-3 can be crossed arbitrarily, it allows for multiple comparison correction for a wide variety of applications.

Notes:
    - There is no function for within-subject significance testing; through cosmo_randomize_targets and a ``for``-loop the user can do that themselves.
    - There is also univariate cosmo_stat for one-sample and two-sample t-tests, and one-way and repeated measures ANOVA.


Do cross-modal decoding across three modalities
-----------------------------------------------
'I have a dataset with three modalities (visual, auditory, tactile) and would like to do both within-modality and cross-modality decoding. How should I proceed?'

:ref:`cosmo_nchoosek_partitioner` can deal with two modalities quite easily, but three or more is not directly supported. Instead you can slice the dataset multiple times to select the samples of interest, as in this example:

    .. code-block:: matlab

        % generate synthetic example data with 3 modalities, 8 chunks
        n_modalities=3;
        ds=cosmo_synthetic_dataset('nchunks',n_modalities*8,'sigma',1);
        ds.sa.modality=mod(ds.sa.chunks,n_modalities)+1; % in range 1:n_modalities
        ds.sa.chunks=ceil(ds.sa.chunks/n_modalities);    % 8 chunks

        % allocate space for output
        accuracies=NaN(n_modalities);

        % do all combinations for training and test modalities
        for train_modality=1:n_modalities
            for test_modality=1:n_modalities

                % select data in train and test modality
                msk=cosmo_match(ds.sa.modality,[train_modality test_modality]);
                ds_sel=cosmo_slice(ds,msk);


                if train_modality==test_modality
                    % within-modality cross-validation
                    partitions=cosmo_nchoosek_partitioner(ds_sel,1);
                else
                    % cross-modality cross-validation
                    partitions=cosmo_nchoosek_partitioner(ds_sel,1,...
                                    'modality',test_modality);
                end

                opt=struct();
                opt.partitions=partitions;
                opt.classifier=@cosmo_classify_lda;

                measure=@cosmo_crossvalidation_measure;

                % Run the measure.
                %
                % (alternatively a searchlight can be used, through
                %
                %   ds_searchlight_result=cosmo_searchlight(ds,nh,measure,opt);
                %
                % where nh is a neighborhood)
                ds_result=measure(ds_sel,opt);
                accuracies(train_modality,test_modality)=ds_result.samples;
            end
        end


Compute classification accuracies manually
------------------------------------------
'I computed predictions using :ref:`cosmo_crossvalidation_measure` with the ``output`` option set to ``'predictions'``, but now I would like to compute the classification accuracies afterwards. How can I do that?'

If ``pred_ds`` is the dataset with predictions, then accuracies can be computed by:

    .. code-block:: matlab

        acc_ds=cosmo_slice(pred_ds,1);  % take single slice
        acc_ds.sa=struct();             % reset sample attributes
        acc_ds.samples=nanmean(bsxfun(@eq,pred_ds.samples,pred_ds.sa.targets));


Merge surface data from two hemispheres
---------------------------------------
'I have surface-based data from two hemispheres. How can I combine these into a single surface dataset structure?'

In the following example, ``ds_left`` and ``ds_right`` are two dataset structs (for example, obtained through :ref:`cosmo_surface_dataset`) from the left and right hemisphere. They can be combined into a single dataset as follows:

    .. code-block:: matlab

        % generate synthetic left and right hemisphere data
        % (this is just example data for illustration)
        ds_left=cosmo_synthetic_dataset('type','surface','seed',1);
        ds_right=cosmo_synthetic_dataset('type','surface','seed',2);

        % Set the number of vertices of the left surface.
        % If the surface is sparse (it does not have data for all nodes), it *may*
        % be necessary to adjust this value manually. In that case, consider to:
        %
        %  - compute the number of vertices, if it is a standardized surface from
        %    MapIcosahedron. If the ld parameter was set to 64, then the number of
        %    vertices is 10*64^2+2=40962.
        %  - get the number of vertices using:
        %       [v,f]=surfing_read('left_surface.asc');
        %       nverts=max(size(v));
        %
        [unused, index]=cosmo_dim_find(ds_left, 'node_indices');
        nverts_left=max(ds_left.a.fdim.values{index});

        % get the offset to set the feature attribute index later
        offset_left=numel(ds_left.a.fdim.values{index});

        % update node indices to support indexing data from two hemispheres
        node_indices=[ds_left.a.fdim.values{index}, ...
                        nverts_left+ds_right.a.fdim.values{index}];
        ds_left.a.fdim.values{index}=node_indices;
        ds_right.a.fdim.values{index}=node_indices;

        % update node indices for right hemisphere
        assert(all(ds_left.fa.node_indices<=offset_left)); % safety check
        ds_right.fa.node_indices=ds_right.fa.node_indices+offset_left;

        % merge hemisphes
        ds_left_right=cosmo_stack({ds_left,ds_right},2);


The resulting dataset ``ds_left_right`` can be stored in a file using :ref:`cosmo_map2surface`.

Visualize and store multiple fMRI volumes
-----------------------------------------
'I have an fMRI volumetric dataset with three volumes. :ref:`cosmo_plot_slices` gives an error when trying to visualize this dataset. How can I visualize the volumes and store them as NIFTI files?'

In this example, ``ds`` is a dataset structure with three volumes. To visualize and store the third volume, do:

    .. code-block:: matlab

        ds3=cosmo_slice(ds,3);              % select third sample (volume)

        cosmo_plot_slices(ds3);             % visualization in CoSMoMVPA

        cosmo_map2fmri(ds3,'volume3.nii');  % for visualization in
                                            % other programs

Note that several fMRI visualization packages can also visualize fMRI datasets with multiple volumes. To store all volumes in a single NIFTI file, simply do:

    .. code-block:: matlab

        cosmo_map2fmri(ds,'all_volumes.nii');

For example, MRIcron_ can be used to visualize each of the volumes in the resulting NIFTI file.

Average along features in a neighborhood
----------------------------------------
'I have defined a :ref:`neighborhood <cosmomvpa_neighborhood>` for my dataset, and now I would like to compute the average across features at each searchlight location. How can I do that?'

To average along features, you can define a new measure:

    .. code-block:: matlab

        function ds_mean=my_averaging_measure(ds)
        % compute the average along features, and copies .sa
        % and .a.sdim, if present

            ds_mean=struct();
            ds_mean.samples=mean(ds.samples,2);

            if cosmo_isfield(ds,'sa')
                ds_mean.sa=ds.sa;
            end

            if cosmo_isfield(ds,'a.sdim')
                ds_mean.a.sdim=ds.a.sdim;
            end

This measure can then be used directly with :ref:`cosmo_searchlight`. Note that the output has the same number of samples as the input dataset (i.e., ``.samples`` has the same number of rows); depending on how the neighborhood is defined, the number of features in the output dataset may either be the same as or different from the input dataset.

It is also possible to define such a measure *inline*; for example, if the input dataset has ``.sa`` but not ``.a.sdim`` (this is the most common case; but exceptions are outputs from :ref:`cosmo_dim_generalization_measure` and :ref:`cosmo_dissimilarity_matrix_measure`), then the following computes the average across voxels at each neighborhood location:

    .. code-block:: matlab

        % tiny dataset: 6 voxels
        ds=cosmo_synthetic_dataset();

        % tiny radius: 1 voxel
        nh=cosmo_spherical_neighborhood(ds,'radius',1);

        % define averaging measure inline
        my_averageing_measure=@(x,opt) cosmo_structjoin(...
                                            'samples',mean(x.samples,2),...
                                            'sa',x.sa);

        % compute average in each neighorhood location across features (voxels)
        ds_mean=cosmo_searchlight(ds,nh,my_averageing_measure);

The line approach may be a bit slower than defining a separate function, but the speed difference is usually not substantial.

Select a time interval in an MEEG dataset
-----------------------------------------

To select only a particular time range, consider the following:

    .. code-block:: matlab

        % for this example, generate synthetic data
        ds=cosmo_synthetic_dataset('type','meeg',...
                                    'size','huge');

        % Select time points between 50 and 300 ms
        time_selector=@(t) t>=.04999 & t<=0.3001;
        time_msk=cosmo_dim_match(ds,'time',time_selector=@);
        %
        % (alternative to the above is

        % slice dataset
        ds_time=cosmo_slice(ds,time_msk,2);

        % Optionally prune the dataset
        % - without cosmo_dim_prune: the output of map2meeg(ds_time) will
        %   have all the time points of the original dataset; data for
        %   missing time points will be set to zero or NaN.
        % - with cosmo_dim_prune: the output of map2meeg(ds_time) will
        %   not contain the removed time points.

        ds_time=cosmo_dim_prune(ds_time);

Note that in the example above, the `time_selector` variable is a function handle that is used to specify a time range. The minimal and maximum values of 0.04999 and 0.30001 (instead of 0.05 and 0.30) are used to address potential tiny rounding errors, as it may be the case that the time points stored in the datasets are not exact multiples of `1/1000`. For example, in the following expression:

    .. code-block:: matlab

        (((0:.1:1)/70)*70)-(0:.1:1)

one might expect a vector of only zeros because of the identities `a==(a+b)-b` and `a==(a/b)/b` (for finite, non-zero values of `a` and `b`), yet both Matlab and GNU Octave return:

    .. code-block:: matlab

        ans =

           1.0e-15 *

          Columns 1 through 6

                 0         0         0   -0.0555         0         0

          Columns 7 through 11

                 0    0.1110         0         0         0

See also: :ref:`cosmo_dim_match`, :ref:`cosmo_slice`, :ref:`cosmo_dim_prune`.


Select a particular channel type in an MEEG dataset
---------------------------------------------------
To select channels of a particular type, consider the following:


  .. code-block:: matlab

        % for this example, generate synthetic data
        ds=cosmo_synthetic_dataset('type','meeg',...
                                    'size','huge');

        %%
        % select channels
        % (the output of chantypes in the command below
        %  indicates which channel types can be selected)
        [chantypes,senstypes]=cosmo_meeg_chantype(ds);

        % in this example, select MEG planar combined channel
        chan_type_of_interest='meg_planar_combined';

        chan_indices=find(cosmo_match(chantypes,...
                                  chan_type_of_interest));

        % define channel mask
        chan_msk=cosmo_match(ds.fa.chan,chan_indices);

        % slice the dataset
        ds_chan=cosmo_slice(ds,chan_msk,2);


        % Optionally prune the dataset
        % - without cosmo_dim_prune: the output of map2meeg(ds_chan) will
        %   have all the channels of the original dataset; data for
        %   missing channels will be set to zero or NaN.
        % - with cosmo_dim_prune: the output of running map2meeg(ds_chan) will
        %   not contain the removed channels.

        ds_chan=cosmo_dim_prune(ds_chan); % to really remove channels

See also: :ref:`cosmo_meeg_chantype`, :ref:`cosmo_slice`, :ref:`cosmo_match`, :ref:`cosmo_dim_prune`.


Use only a subset of channels for my analysis?
----------------------------------------------
'I have time-frequency MEEG data for all channels in the layout. How can I select data from a region of interest, in other words use only a subset? Also, how can I compute the response averaged over the selected channels?'

First, in order to select a subset of channels of interest, consider the following:

    .. code-block:: matlab

        % generate some example data
        ds=cosmo_synthetic_dataset('size','huge','type','timefreq',...
                                'ntargets',1,'nchunks',1);

        % define channels of interest
        channels_of_interest={'MEG0941','MEG0942',...
                              'MEG1831','MEG1832',...
                              };

        % define mask
        msk=cosmo_dim_match(ds,'chan', channels_of_interest);

        fprintf('Selecting %.1f%% of the channels\n',100*mean(msk));

        % select data
        ds=cosmo_slice(ds,msk,2);

        % prune dataset
        ds=cosmo_dim_prune(ds);

Then, to compute the average for each time point and frequency bin:

    .. code-block:: matlab

        % average for each time point and frequency bin seperately
        other_dims={'time','freq'};
        feature_averager=@(x)mean(x,2);
        ds_avg=cosmo_fx(ds,feature_averager,other_dims,2);

        % remove the channel dimension
        ds_avg=cosmo_dim_remove(ds_avg,'chan');

In this case the data is in time-frequency space. If there is only one sample (i.e. .samples is a row vector), it can be visualized as a time by frequency matrix:

    .. code-block:: matlab


        % safety check
        assert(size(ds_avg.samples,1)==1,'only a single sample is supported');

        % unflatten
        [data,labels,values]=cosmo_unflatten(ds_avg);
        assert(isequal(labels,{'freq';'time'})); % safety check

        % make it a matrix
        freq_time=squeeze(data);

        % visualize data
        label_step=5;
        freq_values=values{1};
        n_freq=numel(freq_values);
        keep_freq=1:label_step:n_freq;

        time_values=values{2};
        n_time=numel(time_values);
        keep_time=1:label_step:n_time;

        imagesc(freq_time,[-3 3]);
        colorbar();
        set(gca,'XTickLabel',time_values(keep_time),'XTick',keep_time);
        set(gca,'YTickLabel',freq_values(keep_freq),'YTick',keep_freq);

Should I Fisher-transform correlation values?
---------------------------------------------
'When using :ref:`cosmo_correlation_measure`, :ref:`cosmo_target_dsm_corr_measure`, or :ref:`cosmo_dissimilarity_matrix_measure`, should I transform the data, for example using Fisher transformation (``atanh``)?'

Assuming you would like to do second-level (group) anaysis:

- :ref:`cosmo_correlation_measure`: the correlations are already Fisher transformed (the transformation can be changed and/or disabled using the ``post_corr_func`` option)
- :ref:`cosmo_target_dsm_corr_measure`: correlation values are not Fisher transformed. You could consider applying ``atanh`` to the ``.samples`` output
- :ref:`cosmo_dissimilarity_matrix_measure`: the ``.samples`` field contains, by default, one minus the correlation, and thus its range is the interval ``[0, 2]``. Fisher-transformation should not be used, as values greater than 1 are transformed to complex (non-real) numbers.

Average samples in a deterministic manner?
------------------------------------------
'When using :ref:`cosmo_average_samples` multiple times on the same dataset, I get different avaraged datasets. How can I get the same result every time?'

:ref:`cosmo_average_samples`  has a ``seed`` option; you can use any integer for a seed. For example, if ``ds`` is a dataset, then

  .. code-block:: matlab

        ds_avg=cosmo_average_samples(ds,'seed',1);

will pseudo-deterministically select the same samples upon repeated evaluations of the expression, and thus return the same result

Select only a subset of features in a neighborhood?
---------------------------------------------------
'When using :ref:`cosmo_spherical_neighborhood` with the ``radius`` option, some elements in ``.neighborhood`` have only a few elements. How can I exclude them from subsequent searchlight analyses?

Although :ref:`cosmo_slice` does not support neighborhood structures (yet), consider the following example using tiny example datasets and neighborhoods:

  .. code-block:: matlab

        min_count=4; % in most use cases this is more than 4

        ds=cosmo_synthetic_dataset();
        nh=cosmo_spherical_neighborhood(ds,'radius',1);

        keep_msk=nh.fa.nvoxels>=min_count;

        nh.fa=cosmo_slice(nh.fa,keep_msk,2,'struct');
        nh.neighbors=cosmo_slice(nh.neighbors,keep_msk);

        cosmo_check_neighborhood(nh,ds); % sanity check

Alternatively, :ref:`cosmo_spherical_neighborhood` (and :ref:`cosmo_surficial_neighborhood`) can be used with a 'count' argument - it keeps the number of elements across neighborhoods more constant.

Use multiple-comparison correction for a time course?
-----------------------------------------------------
'I have a matrix of beta values (Nsubjects x Ntimepoints) for each predictor and I want to test for each timepoint (i.e. each column) if the mean beta is significantly different from zero. I ran a t-test but I wonder if I should test for multiple comparisons as well.
What would be the best way to test for significance here?'

You could use multiple comparison correction using Threshold-Free Cluster Enhancement with a temporal neighborhood. Suppose your data is in the following data matrix:

  .. code-block:: matlab

        % generate gaussian example data with no signal;
        n_subjects=15;
        time_axis=-.1:.01:.5;

        n_time=numel(time_axis);
        data=randn(n_subjects,n_time);

then the first step is to put this data in a dataset structure:

    .. code-block:: matlab

        % make a dataset
        ds=struct();
        ds.samples=data;

        % insert time dimension
        ds=cosmo_dim_insert(ds,2,0,{'time'},{time_axis},{1:numel(time_axis)});

You would have to decide how to form clusters, i.e. whether you want to make inferences at the individual time point level, or at the cluster-of-timepoints level. Then use :ref:`cosmo_montecarlo_cluster_stat` to estimate significance.

    .. code-block:: matlab

        % Make a temporal neighborhood for clustering
        %
        % In the following, if
        %
        %   allow_clustering_over_time=true
        % then clusters can form over multiple time points. This makes the analysis
        % more sensitive if there is a true effect in the data over multiple
        % consecutive time points. However, when allow_clustering_over_time=true
        % then one cannot make inferences about a specific time point (i.e.
        % "the effect was significant at t=100ms"), only about a cluster (i.e
        % "the effect was significant in a cluster stretching between t=50 and
        % t=150 ms"). If, on the ohter hand,
        %
        %   allow_clustering_over_time=false
        %
        % then inferences can be made at the individual time point level, at the
        % expensive of sensitivity of detecting any significant effect if there is
        % a true effect that spans multiple consecutive time points
        allow_clustering_over_time=false; % true or false

        % define the neighborhood
        nh_cl=cosmo_cluster_neighborhood(ds,'time',allow_clustering_over_time);

        % set subject information
        n_samples=size(ds.samples,1);
        ds.sa.chunks=(1:n_samples)';     % all subjects are independent
        ds.sa.targets=ones(n_samples,1); % one-sample t-test

        % set clustering
        opt=struct();
        opt.h0_mean=0; % expected mean against which t-test is run
        opt.niter=10000; % 10,000 is recommdended for publication-quality analyses

        % run TFCE Monte Carlo multiple comparison correction
        % in the output map, z-scores above 1.65 (for one-tailed) or 1.96 (for
        % two-tailed) tests are significant
        ds_tfce=cosmo_montecarlo_cluster_stat(ds,nh_cl,opt);



Classify different groups of participants (such as patients versus controls)?
-----------------------------------------------------------------------------
'I have participants in three groups, patients1, patients2, and controls. How can I see where in the brain people these groups can be discriminated above chance level?'

    To do so, consider a standard searchlight using :ref:`cosmo_searchlight` with `cosmo_crossvalidation_measure`. Group membership is set in ``.sa.targets``. Since all participants are assumed to be independent, values in ``.sa.chunks`` are all unique.

    Correcting for multiple comparisons is more difficult. Since it is not possible to do a 'standard' t-test (two groups) or ANOVA F-test (three or more groups), instead generate null datasets manually by randomly permuting the ``.sa.targets`` labels. Then use these null datasets directly as input for :ref:`cosmo_montecarlo_cluster_stat` without computing a feature statistic.

    Consider the following example:

    .. code-block:: matlab

        % set number of groups and number of participants in each group
        ngroups=3;
        nchunks=10;

        % generate example dataset with some signal that discriminates
        % the participants
        ds=cosmo_synthetic_dataset('ntargets',ngroups,'nchunks',nchunks);

        % since all participants are independent, all chunks are set to
        % unique values
        ds.sa.chunks(:)=1:(ngroups*nchunks);

        % define partitions
        fold_count=50;
        test_count=1;
        partitions=cosmo_independent_samples_partitioner(ds,...
                                'fold_count',fold_count,...
                                'test_count',test_count);

        % define neighborhood
        radius_in_voxels=1; % typical is 3 voxels
        nh=cosmo_spherical_neighborhood(ds,'radius',radius_in_voxels);

        % run searchlight on original data
        opt=struct();
        opt.classifier=@cosmo_classify_lda;
        opt.partitions=partitions;

        result=cosmo_searchlight(ds,nh,...
                            @cosmo_crossvalidation_measure,opt);

        % generate null dataset
        niter=100; % at least 1000 is iterations is recommended, 10000 is better
        ds_null_cell=cell(niter,1);

        for iter=1:niter
            ds_null=ds;

            ds_null.sa.targets=cosmo_randomize_targets(ds_null);

            % update partitions
            opt.partitions=cosmo_independent_samples_partitioner(ds_null,...
                                'fold_count',fold_count,...
                                'test_count',test_count);


            null_result=cosmo_searchlight(ds_null,nh,...
                                    @cosmo_crossvalidation_measure,opt);

            ds_null_cell{iter}=null_result;
        end
        %%

        % Since partitions are balanced, chance level
        % is the inverse of the number of groups. For example,
        % with 4 groups, chance level is 1/4 = 0.25 = 25%.
        chance_level=1/ngroups;
        tfce_dh=0.01; % should be sufficient for accuracies

        opt=struct();
        opt.h0_mean=chance_level;
        opt.dh=tfce_dh;
        opt.feature_stat='none';
        opt.null=ds_null_cell;

        cl_nh=cosmo_cluster_neighborhood(result);

        %% compute TFCE map with z-scores
        % z-scores above 1.65 are signficant at p=0.05 one-tailed.

        tfce_map-cosmo_montecarlo_cluster_stat(result,cl_nh,opt);

When running an MEEG searchlight, have the same channels in the output dataset as in the input dataset?
-------------------------------------------------------------------------------------------------------
'When I run an MEEG searchlight over channels, the searchlight dataset map has more channels than the input dataset. Is this normal?'

This is quite possible because the :ref:`cosmo_meeg_chan_neighborhood` uses, by default, the layout that best fits the dataset. The output from the searchlight has then all channels from this layout, rather than only the channels from the input dataset. This is done so that in individual particpants different channels can be removed in the preprocessing step, while group analysis on the output maps can be done on maps that have the same channels for all participants.

If you want to use only the channels from the input dataset (say ``ds``) you can set the ``label`` option to 'dataset'. See the following example, where ``chan_nh`` has only channels from the input dataset.

    .. code-block:: matlab

        chan_nh=cosmo_meeg_chan_neighborhood(ds,'count',5,'label','dataset')


Save MEEG data when I get the error "value for fdim channel label is not supported"?
------------------------------------------------------------------------------------
'When I try to export MEEG searchlight maps with channel information as MEEG data using ``cosmo_map2meeg(ds,'-dattimef')``, I get the error "value for fdim channel label is not supported"? Also I am unable to visualize the data in FieldTrip. Any idea how to fix this?'

This is probably caused by a wrong feature dimension order when crossing the neighborhood with :ref:`cosmo_cross_neighborhood`. The FieldTrip convention for the order is ``'chan','time'`` (for time-locked data) or ``'chan','time','freq'`` (for time-frequency data). (As of 16 December 2016, a warning has been added if a non-standard dimension order is detected).

It is possible to change the feature dimension order afterwards. First, the feature dimension order for a dataset struct ``ds`` can be displayed by running:

    .. code-block:: matlab

        disp(ds.a.fdim.labels)

If the order is, for example, ``'freq', 'time', 'chan'`` then the channel dimension should be moved from position 3 to position 1 to become ``'chan','freq','time'``. To move the channel dimension, first remove the dimension, than insert it at another position, as follows:

    .. code-block:: matlab

        label_to_move='chan';
        target_pos=1;
        [ds,attr,values]=cosmo_dim_remove(ds,{label_to_move});
        ds=cosmo_dim_insert(ds,2,target_pos,{label_to_move},values,attr);

Run a 2 x 2 within-subject ANOVA?
---------------------------------
'I would like to run a 2 x 2 ANOVA over participants where both factors are within-participant (also known as repeated-measures ANOVA). Can I use CoSMoMVPA to get the main effects and interaction statistics?'

You can, but currently not directly: it involves a bit of manual work. The key thing is that in a 2 x 2 repeated measures ANOVA, main effects and interaction can all be expressed as one-sample t-tests. Say that for a single participant there are four conditions: A1, A2, B1, and B2. In CoSMoMVPA we would express this as a dataset structure ``ds`` with ``ds.samples`` of size ``4 x NF``, where ``NF`` is the number of features. Now compute:

    .. code-block:: matlab

        % main effect A vs B: A1+A2-B1-B2.
        dsAvsB=cosmo_slice(ds,1);
        dsAvsB.samples=ds.samples(1,:)+ds.samples(2,:)-ds.samples(3,:)-ds.samples(4,:)

        % main effect 1 vs 2: A1-A2+B1-B2
        ds1VS2=cosmo_slice(ds,1);
        ds1VS2 =ds.samples(1,:)-ds.samples(2,:)+ds.samples(3,:)-ds.samples(4,:)

        % interaction: A1-A2-B1+B2
        dsinteraction=cosmo_slice(ds,1);
        dsinteraction=ds.samples(1,:)-ds.samples(2,:)-ds.samples(3,:)+ds.samples(4,:)


Repeat the process for each participant. For each analysis of interest (two main effects and the interaction) separately, follow the process of a one-sample t-test as explained elsewhere in the FAQ: stack the dataset from the participants using :ref:`cosmo_stack`, assign ``.sa.chunks`` to be all unique, assign ``.sa.targets`` to be all the same, and then use :ref:`cosmo_stat` (for feature-wise stats with no correction for multiple correction) or :ref:`cosmo_montecarlo_cluster_stat` (for correction with multiple comparisons).

Note the advantage of a (signed) t-test over an (always positive) F value: the t value tells you which way the main effect or interaction goes, whereas the F value does not tell this.


Use a FieldTrip source dataset that uses a 'fake' channel structure
-------------------------------------------------------------------
'I use an analysis pipeline where MEEG source data in MNI space is represented (faked) as a sensor-like structure [such as done by some at CIMeC, Trento; or University of Salzberg, Austria]. In particular, the FieldTrip dataset structure is

   .. code-block:: text

        src_ft =

            label: {2982x1 cell}
           dimord: 'chan_freq_time'
             freq: [1x25 double]
             time: [1x15 double]
        powspctrm: [2982x25x15 double]
              cfg: [1x1 struct]

where the labels are strings from ``'1'`` to ``'2972'``. These labels refer to positions in source space using

   .. code-block:: text

        template_grid =`

         xgrid: [-8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8]
         ygrid: [-11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8]
         zgrid: [-7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9]
           dim: [17 20 17]
           pos: [5780x3 double]
          unit: 'cm'
        inside: [5780x1 logical]
           cfg: [1x1 struct]

where there are 2972 positions in the .inside field that are equal to ``true`` representing the voxels in the brain. How can I use these dataset structures in CoSMoMVPA?'

The ``src_ft`` struct can be converted to a dataset structure using

    .. code-block:: matlab

        src_ds=cosmo_meeg_dataset(src_ft);

but it uses channel labels (representing voxels) for which the positions are not known (and thus, neighborhoods cannot be used). To add the position information, you can use the following helper function

    .. code-block:: matlab

        function ds=convert_ds_mni_grid(ds,template_grid)
        % Converts dataset with 'fake' channels numbered '1' to 'N' (N numeric)
        % and an mni template structure
        %
        % Inputs:
        %   ds              dataset struct with first fdim dimension being
        %                   'chan' with "fake" channels representing MEEG source
        %                   structure
        %   template_grid   struct with fields .{x,y,z}grid and .inside


            check_inputs(ds,template_grid);

            % voxels representing the brain
            inside=template_grid.inside;
            pos=template_grid.pos(inside,:)';

            % change first dimension to position
            ds.a.fdim.values{1}=pos;
            ds.a.fdim.labels{1}='pos';
            chan=ds.fa.chan;
            ds.fa=rmfield(ds.fa,'chan');
            ds.fa.pos=chan;

            % sanity check
            cosmo_check_dataset(ds);

        function check_inputs(ds,template_grid)
            if isfield(ds,'label')
                error(['First input is not a CoSMo dataset structure. '...
                        'Use cosmo_meeg_dataset to convert to a CoSMo structure']);
            end

            cosmo_check_dataset(ds);

            if ~isequal(ds.a.fdim.labels{1},'chan')
                error('First fdim must be channel');
            end

            raise=true;
            cosmo_isfield(template_grid,...
                            {'xgrid','ygrid','zgrid','pos','inside'},...
                            raise);

            labels=ds.a.fdim.values{1};
            n_inside=sum(template_grid.inside);
            if n_inside~=numel(labels)
                error('Source count mismatch: %d ~= %d', n_inside, numel(labels));
            end

            numeric_labels=cellfun(@str2num,labels,'UniformOutput',false);
            expected_numeric_labels=arrayfun(@(x)x,1:n_inside,...
                                    'UniformOutput',false);

            if ~isequal(expected_numeric_labels,numeric_labels)
                error(['Labels are not as expected. This could mean that '...
                        'you are using this function not as intended. '...
                        'Proceed carefully']);
            end

and then get a 'proper' dataset in source space using

    .. code-block:: matlab

        ds=convert_ds_mni_grid(src_ds,template_grid);





Run `cosmo_montecarlo_cluster_stat` on a cluster with multiple nodes
--------------------------------------------------------------------
'I am running group statistics using :ref:`cosmo_montecarlo_cluster_stat` but it is very slow when using the recommended 10,000 iterations. I have access to a computer cluster. Can I use the cluster to speed up the computations?'

Yes, although it requires a bit of extra work. You would run  :ref:`cosmo_montecarlo_cluster_stat` on multiple computer nodes with fewer iterations, then combine their results. Consider the following script (and comments in there):

    .. code-block:: matlab

        % example on combining results of multiple invocations of
        % cosmo_montecarlo_cluster_stat into a single dataset with effectively
        % more iterations
        %
        % Use case: running 10,000 iterations with cosmo_montecarlo_cluster_stat
        % on a single machine takes to long, but there are 50 computer nodes
        % available in a computer cluster. Then each node can do 200 iterations;
        % results from each node are combined afterwards to get
        % effectively 10,000 iteraations
        %

        % generate some random data for 20 participants
        nsubjects=20;
        ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',nsubjects,...
                                'sigma',0,'size','normal','seed',2);

        % Generate TFCE z-scores in 50 blocks, each with 20 iterations.
        %
        % In this example a simple for-loop is used to compute results for each
        % block, but typically results in each block are computed in different
        % Matlab sessions (e.g. when using multiple computer nodes in a clusters).
        % In that case, a script or function should be used that stores the result
        % (a dataset with TFCE z-scores) for each block in a .mat file. For
        % example, the following function could be run on each computing node (each
        % with a different value for block_id):
        %
        %     function run_tfce_block(block_id,niter_per_block)
        %
        %     % load dataset with data from each subject
        %     ds=load('my_subject_data.mat');
        %
        %     % define neighborhood
        %     nh=cosmo_cluster_neighborhood(ds);
        %
        %     % set TFCE options
        %     opt=struct();
        %     opt.niter=niter_per_block;
        %     opt.h0_mean=0;
        %     opt.seed=block_id;
        %
        %     % compute TFCE z-scores
        %     z_ds=cosmo_montecarlo_cluster_stat(ds,nh,opt);
        %
        %     % save results to disk
        %     fn=sprintf('tfce_z_block%02d.mat',block_id);
        %     save(fn,'-struct','z_ds');
        %
        % After running this function for aech block, the resulting .mat files
        % would then be loaded and combined with cosmo_stack as illustrated below.
        %
        % If a seed is set for cosmo_montecarlo_cluster_stat, then it is crucial
        % that different seed values are used in different blocks (otherwise each
        % block would yield identical results)

        nblocks=50;
        niter_per_block=20;

        ds_tfce_cell=cell(nblocks,1);
        for k=1:nblocks
            % Set TFCE options for each block.
            % A different seed value is used for each block to obtain repeatable
            % (determnistic) but different results in each block
            opt=struct();
            opt.niter=niter_per_block;
            opt.h0_mean=0;
            opt.seed=k;

            % define the neighborhood
            nbrhood=cosmo_cluster_neighborhood(ds);

            % compute TFCE z-scores
            ds_tfce_k=cosmo_montecarlo_cluster_stat(ds,nbrhood,opt);

            % store result
            ds_tfce_cell{k}=ds_tfce_k;
        end

        % combine TFCE z-scores from all blocks into one dataset
        % (due to a tail cutoff protection this approach is very minorly
        % conservative in its p-value computation)
        ds_tfce_all=cosmo_stack(ds_tfce_cell);

        % convert TFCE z-scores to TFCE p-values
        % (the p-values represent the left tail probability)
        ps_all=normcdf(ds_tfce_all.samples);

        % compute the average p value over blocks, for each feature separately
        combined_ps=mean(ps_all,1);

        % convert TFCE p value back to TFCE z-scores
        combined_z=norminv(combined_ps);

        % make a new dataset in which the combined z-scores
        % are going to be stored
        ds_tfce=cosmo_slice(ds_tfce_all,1);

        % ensure empty sample attributes
        ds_tfce.sa=struct();

        % store dataset
        ds_tfce.samples=combined_z;
        cosmo_check_dataset(ds_tfce)

Why should I consider re-meaning when doing representational similarity analysis (RSA)?
---------------------------------------------------------------------------------------
'In the * :ref:`cosmo_target_dsm_corr_measure` *documentation it is recommended to subtract the mean activity pattern first. Why is this recommended?'

This is explained well in :cite:`DK17`:

    `Activity estimates commonly co-vary together across fMRI imaging runs, because all activity estimates within a partition are measured relative to the same resting baseline. This positive correlation can be reduced by subtracting, within each partition, the mean activity pattern (across conditions) from each activity pattern. This makes the mean of each measurement channel (across condition) zero and thus centers the ensemble of points in activity-pattern space that is centered on the origin.'



Import BrainStorm data
----------------------
'I have preprocessed my data using BrainStorm. How can I import time-locked and time-frequency data in CoSMoMVPA?'

Currently this functionality is not included in :ref:`cosmo_meeg_dataset`, but below are some example scripts that illustrate the approach.

For time-locked data:

    .. code-block:: matlab

        % Example script showing importing BrainStorm M/EEG time-locked data into
        % CoSMoMVPA.
        %
        % The result is a CoSMoMVPA dataset structure 'ds'
        %
        % NNO Sep 2017
        %
        % Input data:
        %   '195_trial001.mat' : contains data in FieldTrip timelock struct format,
        %                        with data from a single trial, for 701 time points
        %                        and 319 channels
        %
        %                             template_trial =
        %
        %                                 dimord: 'chan_time'
        %                                    avg: [319x701 double]
        %                                   time: [1x701 double]
        %                                  label: {319x1 cell}
        %                                   grad: [1x1 struct]
        %
        %   'out.mat'          : 3D array of size 180 x 319 x 701
        %                           180 trials, 90 of condition A followed by
        %                                       90 of condition B
        %                           319 channels
        %                           701 time points
        %

        % Indices of the trial conditions
        % - the first 90 trials are condition A
        % - the nextt 90 trials are condition B
        trials_condA=1:90;
        trials_condB=91:180;

        % load all data
        all_data=importdata('out.mat');

        % get template trial
        template_trial=load('195_trial001.mat');

        % set trial condition in a vector
        targets=NaN(numel(trials_condA)+numel(trials_condA),1);
        targets(trials_condA)=1;
        targets(trials_condB)=2;

        % count number of trials
        n_trials=numel(targets);

        % just verify that trial count matches
        assert(numel(targets)==size(all_data,1),'trial count mismatch');

        % allocate space for output
        ds_cell=cell(n_trials,1);

        % convert each trial
        for k=1:n_trials
            % make a copy from the template
            trial=template_trial;

            % take data from trial
            trial.avg(:,:)=squeeze(all_data(k,:,:));

            % convert to CoSMo struct
            ds_trial=cosmo_meeg_dataset(trial);

            % all trials are assumed to be independent
            ds_trial.sa.chunks=k;

            % set condition
            ds_trial.sa.targets=targets(k);

            % since we are merging trials, this is not an average anymore
            % (this is a bit of a hack since we're not really importing from
            % FieldTrip, but BrainStorm sets (arguablye misleading) the single
            % trial data as if it is an average)
            ds_trial.a.meeg=rmfield(ds_trial.a.meeg,'samples_field');

            % store dataset
            ds_cell{k}=ds_trial;
        end

        % merge all trials into a big dataset
        ds=cosmo_stack(ds_cell);

For time-frequency data:

    .. code-block:: matlab

        % Brainstorm time-frequency data import in CoSMoMVPA
        %
        % The script below takes data from BrainStorm representing a single trial
        % in time-frequency space, and converts it to a CoSMoMVPA dataset
        % structure. The contents of TFmask (representing a mask) is applied.
        %
        % The input data bs_data (BrainStorm data) has the following structure:
        %
        %     bs_data =
        %
        %                TF: [306x701x60 double]
        %            TFmask: [60x701 logical]
        %           Comment: 'Power,1-60Hz (MEG)'
        %          DataType: 'data'
        %              Time: [1x701 double]
        %             Freqs: [1x60 double]
        %          RowNames: {1x306 cell}
        %           Measure: 'power'
        %            Method: 'morlet'
        %
        %           (with some fields omitted).
        %

        % bs_data contains time-freq data from BrainStorm

        tf_arr=bs_data.TF;
        tf_msk=bs_data.TFmask;
        n_chan=size(tf_arr,1);

        % get single trial data of size 1 x Nchan x NTime x NFreq
        tf_msk_tr=tf_msk';
        msk=repmat(reshape(tf_msk_tr,[1 size(tf_msk_tr)]),[n_chan 1 1]);

        % sanity check that mask size matches TF data size
        assert(isequal(size(msk),size(tf_arr)));

        tf_4d=reshape(tf_arr,[1 size(bs_data.TF)]);
        msk_4d=reshape(msk,[1 size(msk)]);

        % make it a dataset
        labels={'chan','time','freq'};
        values={bs_data.RowNames,bs_data.Time,bs_data.Freqs};
        full_ds=cosmo_flatten(tf_4d,labels,values);

        % convert mask into dataset
        msk_ds=cosmo_flatten(msk_4d,labels,values);

        % apply mask
        ds=cosmo_slice(full_ds,msk_ds.samples,2);

        % label it as meeg data
        ds.a.meeg=struct();

        % sanity check
        cosmo_check_dataset(ds);

        % illutration of mapping data to FieldTrip structure
        data_ft=cosmo_map2meeg(ds);

Note that there is no example script (yet) showing how to transform this data back into BrainStorm.

Make a merged hemisphere from a left and right hemisphere
---------------------------------------------------------
'Using Freesurfer I generated left and right hemisphere surface files. How can I combine them into a merged hemisphere?'

You could use the function below.

    .. code-block:: matlab

        function [v_merged, f_merged] = merge_surfaces(filenames)
        % merge surface filesep
        %
        % Input:
        %   filenames:      cell filenames of surfaces to merge, for example
        %                   these can be '.asc'  files as generated by FreeSurfer's
        %                   recon_all
        %
        % Output:
        %   v_merged        Nx3 matrix with vertex coordinates for N vertices
        %   f_merged        Mx3 matrix with face indices for M faces
        %
        % Example:
        %   % merge left and right hemispheres of pial surface
        %   fns = {'lh.pial.asc', 'rh.pial.asc'}
        %   [v,f]=merge_surfaces(fns)
        %   surfing_write('mh.pial.asc',v,f);
        %
        % Note:
        % - this function uses surfing_read from the Surfing toolbox.
        %   See https://github.com/surfing/surfing
        % - the output can be saved with surfing_write
        %
        % Nick Oosterhof 2018-10-12

            if ~iscellstr(filenames)
                error('input must be cell with filenames')
            end

            n_surfaces = numel(filenames);
            v_s = cell(n_surfaces,1);
            f_s = cell(n_surfaces,1);

            n_total = 0;
            for k=1:n_surfaces
                filename = filenames{k};
                [v, f] = surfing_read(filename);
                cosmo_disp(v)
                cosmo_disp(f)

                % keep the vertex coordinates
                v_s{k} = v;

                % update face indices to take into account previous input surfaces
                f_s{k} = f + n_total;

                # update index of first face for next surface
                n_vertices = size(v,1);
                n_total = n_total + n_vertices;
            end

            v_merged = cat(1,v_s{:});
            f_merged = cat(1,f_s{:});


Compute the correlation between two dissimilarity matrices
----------------------------------------------------------
'I would like to correlate behavioural ratings with a theoretical model, how can I do this'

You can use the example below to correlate two dissimilarity matrices; these can also be

    .. code-block:: matlab

        % two dissimilarity matrices
        x_dsm = [0 1 3 2;
                 1 0 3 4;
                 3 3 0 1;
                 2 4 1 0];

        y_dsm = [0 5 3 1;
                 5 0 1 2;
                 3 1 0 0;
                 1 2 0 0];

        % convert to linear vectors
        x_vec = squareform(x_dsm);
        y_vec = squareform(y_dsm);

        % compute Spearman correlation between the matrices
        % ( - for non-Parametric Spearman correlations, use 'Spearman'.)
        % ( - Matlab's corr can be used instead)
        r = cosmo_corr(x_vec(:), y_vec(:), 'Pearson')

For analysis at the group level, compute for each participant the correlation between their behavioural ratings, then use a one-sample t-test against a difference of zero.


.. include:: links.txt
