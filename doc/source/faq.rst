.. _faq: 

--------------------------------------
Frequently Asked/Anticipated Questions
--------------------------------------
**What, yet another MVPA toolbox? How is this toolbox different from others?**
    Indeed, another MVPA toolbox, it has features that may be attractive:

    + *Simple*, *light-weight*, and *modular* Matlab_ functions .
    + Provides implementations of *all common MVPA analyses* for fMRI (correlations, representational similarity, classifiers, crossvalidation, searchlight analysis).
    + Support for most *fMRI data formats*: AFNI, BrainVoyager, ANALYZE and NIFTI.
    + Various runnable *example scripts* and *exerices*, describing both on how to perform certain types of analyses (i.e., from a user perspective), and on how typical MVP analyses can be implemented (from a programmer persective).

    For comparison, here is a list of other MVPA toolboxes: 

    + PyMVPA_ is implemented in Python (it provided inspiration for the dataset structure and semantics). Our toolbox implements the most commonly used MVP analyses, but not all of them, in Matlab. Some labs only use Matlab for data analsis, so CoSMoMVPA may be easier for those to use. 
    + PRoNTo_ is another Matlab MVPA toolbox, that is much wider in scope and provies a Graphical User Interface. In contrast, our toolbox is more minimalistic and bare-bones, meaning it has much fewer lines of code and is simpler in design. This may make it easier to understand its functions, and to modify.
    + Searchmight_ is aimed at searchlight analyses (and does these very fast). Although our toolbox does support such analyses (albeit slower), it also supports other types of analyses not covered by Searchmight.
    + `Princeton MVPA`_ toolbox is a sophisticated toolbox but (we think) harder to use, and is currently not under active development. 

    To our knowledge, the other MVPA toolboxes support fewer data formats; we are neither aware of another toolbox that supports BrainVoyager datasets, nor of one that supports both NIFTI or ANALYZE, and AFNI, natively.


**What does CoSMoMVPA *not* provide?**
    It does not provide (and probably never will):

    + Preprocessing of data. For fMRI data it assumed that the data has been preprocessed and, in most use-case scenarios, has been analyzed using the General Linear Model.
    + Implementations of complicated analyses (such as hyperalignment, nested cross validation, recursive feature elimination). If you want to do these, consider using PyMVPA_.
    + A Graphical User Interface (GUI). First, it's a lot of work to build such a thing. Second, writing the code to perform the analyses could be considered as more instructive: it requires one to actually *think* about the analysis, rather than just clicking on buttons. 
    + Pretty visualization of fMRI data. Although there is basic functionality for showing slices of fMRI data (through ``cosmo_plot_slices``, for better visualization we suggest to use either your preferred fMRI analysis package, or MRIcron_.

    Also, it does not make coffee for you.

**How fast does it run?**
CoSMoMVPA_ is not a speed monster, but on our hardware (Macbook Pro early 2012) a searchlight using typical fMRI data takes one minute for simple analyses (correlation split-half), and a few minutes for more advanced analyses (classifier with cross-validation). Analyses on regions of interest are typically completed in seconds.

**What should I use as input for MVPA**
Unless you know exactly what you are doing, in fMRI land we would recommend to either:

- Apply the GLM for each run seperately, with separate predictors for each condition. Each run is a chunk, and each experimental condition is a target. You can use either beta estimates or t-statistics. 
- Split the data in halves (even and odd) and apply the GLM to each of these (i.e. treat the experiment as consisting of two 'runs'). In this case there are two chunks, and the same number of unique targets as there are experimental conditions.

**Who are the developers of CoSMoMVPA?**
    Currently the developers are Nikolaas N. Oosterhof and Andrew C. Connolly. In the code you may find their initials (``NNO``, ``ACC``) in commented header sections.

**Which file-formats are supported?**
    At present only fMRI formats are supported:

    + AFNI (``+{orig,trlc}.{HEAD,BRIK[.gz]}``), through the `AFNI Matlab`_ library.
    + BrainVoyager (``.vmp``, ``.glm``), through the NeuroElf_ Matlab toolbox.
    + NIFTI (``.nii``; ``.nii.gz`` on Unix-like_ platforms).
    + ANALYZE (``.hdr``/``.img``).

    Future releases may include MEEG formats as well.

**Which classifiers are available?**
    + Naive Bayes, multiclass (``cosmo_classify_naive_bayes``).
    + Nearest Neighbor, multiclass (``cosmo_classify_nn``).
    + Support Vector Machine, multiclass (``cosmo_classify_svm``; requires the Matlab statistics toolbox).

**Which platforms does it support?**
    It has been tested with Windows, Mac and Linux.

**What future features can be expected?**
    Time permitting, there are some features that may be added in the future:

    + Support for MEEG datasets (first in line are FieldTrip and EEGLab).
    + Spatial clustering.
    + Threshold-Free Cluster Enhancement.
    + Multiple-comparison correction for group analysis.
    + Input/output support in PyMVPA_, allowing for an easy transition to PyMVPA.
    + Surface-based searchlights.

**How can I contact the developers?**
    Please send an email to a@c or b@c, where a=andrew.c.connolly, b=nikolaas.n.oosterhof, c=dartmouth.edu.

**Is there a mailinglist?**
    There is the `CoSMoMVPA Google group`_.

.. include:: links.rst
