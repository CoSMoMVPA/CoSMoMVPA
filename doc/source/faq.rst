.. _faq:

--------------------------------------
Frequently Asked/Anticipated Questions
--------------------------------------
**What, yet another MVPA toolbox? How is this toolbox different from others?**
    Indeed, another MVPA toolbox, featuring:

    + *Simple*, *light-weight*, and *modular* Matlab_ functions .
    + Provides implementations of *all common MVPA analyses* for (correlations, representational similarity, classifiers, crossvalidation, searchlight analysis).
    + Aims to support volumetric fMRI, surface-based fMRI, and MEEG data alike.
    + Support a variety of formats:

        * fMRI volumetric (:ref:`cosmo_fmri_dataset` and :ref:`cosmo_map2fmri`): AFNI, BrainVoyager, ANALYZE, NIFTI. It can also load ``SPM.mat`` files from SPM_.
        * fMRI surface-based (:ref:`cosmo_surface_dataset` and :ref:`cosmo_map2surface`): Brainvoyager, AFNI (NIML), GIFTI
        * MEEG (:ref:`cosmo_meeg_dataset` and :ref:`cosmo_map2meeg`): Fieldtrip, EEGLab.

    + Various runnable *example scripts* and *exerices*, describing both on how to perform certain types of analyses (i.e., from a user perspective), and on how typical MVP analyses can be implemented (from a programmer persective).

    For comparison, here is a list of other MVPA toolboxes:

    + PyMVPA_ is implemented in Python (it provided inspiration for the dataset structure and semantics). Our toolbox implements the most commonly used MVP analyses (but not all of them) in Matlab. Those who are familiar with Matlab but not with Python may find CoSMoMVPA easier to use.
    + PRoNTo_ is another Matlab MVPA toolbox, that is much wider in scope and provies a Graphical User Interface. In contrast, our toolbox is more aimed on the analysis itself rather than providing a GUI, meaning it has much fewer lines of code and is simpler in design. This may make it easier to understand its functions, and to modify.
    + Searchmight_ is aimed at searchlight analyses (and does these very fast). CoSMoMVPA does support such analyses (albeit slower), but also supports other types of analyses not covered by Searchmight.
    + `Princeton MVPA`_ toolbox is a sophisticated toolbox but (we think) harder to use, and is currently not under active development.

    To our knowledge, the other MVPA toolboxes support fewer data formats; we are neither aware of another toolbox that supports BrainVoyager datasets, nor of one that supports both NIFTI or ANALYZE, and AFNI, natively.


**What does CoSMoMVPA *not* provide?**
    It does not provide (and probably never will):

    + Preprocessing of data. For fMRI data it assumed that the data has been preprocessed and, in most use-case scenarios, has been analyzed using the General Linear Model.
    + Implementations of complicated analyses (such as hyperalignment, nested cross validation, recursive feature elimination). If you want to do these, consider using PyMVPA_.
    + A Graphical User Interface (GUI). First, it's a lot of work to build such a thing. Second, writing the code to perform the analyses could be considered as more instructive: it requires one to actually *think* about the analysis, rather than just clicking on buttons.
    + Pretty visualization of fMRI data. Although there is basic functionality for showing slices of fMRI data (through ``cosmo_plot_slices``, for better visualization we suggest to use either your preferred fMRI analysis package, or MRIcron_.

    Also, it does not make coffee for you.

**Does it integrate with PyMVPA?**
    The ``mvpa2/datasets/cosmo.py`` module in PyMVPA_ provides input and output support between CoSMoMVPA and PyMVPA datasets and neighborhoods. This means that, for example, searchlights defined in CoSMoMVPA can be run in PyMVPA (possibly benefitting from its multi-threaded implementation), and the results converted back to CoSMoMVPA format.

**Does it run on Octave?**
    Allmost all functionality runs in Octave_, but there may be parts that function not so well. Unit tests do not work in Octave because some object-oriented features are not supported.

**How fast does it run?**
    CoSMoMVPA_ is not a speed monster, but on our hardware (Macbook Pro early 2012) a searchlight using typical fMRI data takes one minute for simple analyses (correlation split-half), and a few minutes for more advanced analyses (classifier with cross-validation). Analyses on regions of interest are typically completed in seconds.

**What should I use as input for MVPA?**
    We suggest the following:

    * fMRI options:

        - Apply the GLM for each run seperately, with separate predictors for each condition. Each run is a chunk, and each experimental condition is a target. You can use either beta estimates or t-statistics.
        - Split the data in halves (even and odd) and apply the GLM to each of these (i.e. treat the experiment as consisting of two 'runs'). In this case there are two chunks, and the same number of unique targets as there are experimental conditions.

    * MEEG options:

        - Assign chunks based on the run number
        - If the data in different trials in the same run can be assumed to be independent, use :ref:`cosmo_chunkize`.

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

    + Spatial clustering.
    + Threshold-Free Cluster Enhancement.
    + Multiple-comparison correction for group analysis.

**How can I contact the developers?**
    Please send an email to a@c or b@c, where a=andrew.c.connolly, b=nikolaas.n.oosterhof, c=dartmouth.edu.

**Is there a mailinglist?**
    There is the `CoSMoMVPA Google group`_.

.. include:: links.txt
