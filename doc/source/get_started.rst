.. _`get started`: Get started

===========
Get Started
===========

^^^^^^^^^^^^^
Prerequisites
^^^^^^^^^^^^^

CoSMoMVPA_ requires:

- a working installation of Matlab_.
- the CoSMoMVPA Matlab code (see :ref:`download`). 
    + see also :ref:`download` for external toolboxes that provide support for other file formats.
- An advanced beginner level of Matlab programming (see below)
- An advanced beginner level of cognitive neuroscience (fMRI) data analysis (see below)
- A basic understanding of MVPA concepts.
- Familiarity with the dataset, classifier and measure concepts used in CoSMoMVPA

Matlab experience
+++++++++++++++++
CoSMoMVPA_ is written with simplicity and mind, and therefore does not require one to be a Matlab expert to use it. However, some minimal knowledge is required. To assess your knowledge of Matlab, below we describe some (subjectively chosen) criteria. 

Using these criteria, we would argue that using CoSMoMVPA to analyze your data requires at least the *advanced beginner* level. In order to understand the internal functionalities, and/or to contribute code, the *competent* level is required. The  while the *proficient* level is preferable. 

An advanced *beginner* should:

- be able to start Matlab
- be able to modify the Matlab path.
- know what a ``array``, ``cell`` and ``struct`` data object is, and how to store data in and retrieve data from them.
- understand the difference between a ``numeric``, ``character`` and ``boolean`` data type.
- know the difference between a ``script`` and a ``function``.
- know how to use a ``function``, and see the ``help`` documentation associated with a function.
- be familiar with ``for`` and ``while`` loops.
- understand the ``if`` statement.

In addition, the *competent* user should:

- understand and be able to define and use a function handle.
- be able to allocate space for data.
- know the difference between using a binary mask and indices to access values in a ``cell`` or ``struct``.
- be familiar with linear and subscripts to access values in a ``cell`` or ``struct``.
- be able to use ``varargin`` and ``nargin``.
- perform string manipulations.

In addition, the *proficient* user should:

- understand function handles.
- be able to use ``bsxfun``.
- be able to use recursion.
- be able to derive the space- and time complexity of an algorithm, and able to design an algorithm that minimizes these.
- make informed decisions about which functionality should be separated into different functions. 

(We have no idea what an *expert* user should be able to do, because we don't consider ourselves in that category).

Cognitive neuroscience experience
+++++++++++++++++++++++++++++++++
This is not a tutorial on how to preprocess cognitive neuroscience data; it is assumed that the user is already familiar with these. 

For *fMRI* users should:

- be able to preprocess data (e.g. motion correction, slice time correction, signal normalization). 
- be able to create a mask of either the whole brain or regions of interest.
- be able to run the General Linear Model to get beta estimates and t-statistics.
- understand the basic ideas behind MVPA.

There is currently no support for *MEEG*, although we hope to add it in the future.

^^^^^^^^^^^^^^^^^^
CoSMoMVPA concepts
^^^^^^^^^^^^^^^^^^

There are a few concepts used in CoSMoMVPA that may require some explanation: datasets, classifiers, and measures.

Multivariata pattern analysis (MVPA)
++++++++++++++++++++++++++++++++++++

Before diving into MVPA, let's consider a series of example questions that one might be interested in:

- Does gas price affect how much people use their car?
- Are the topics of tweets affected by the Dow Jones index?
- Where in the brain are categorical similarities of animal species represented?
- Does whether a person hears a sound or not depend on his brain state *before* the sound was presented?
- Can brain responses associated with viewing different pictures be explained by measurements of single neurons?

Although in the age of truthiness one may have intuitive reponses to these questions, a more scientific approach entails collecting data to see if an association can be found between effects of interest. MVPA can help by providing a sensitive analysis tool to address these and many other questions.

First we present a general case to explain how MVPA can be applied to a wide variety of cases; then we focus towards applying this to fMRI analysis.

**'UVA'**

Taking one step back, in *univariate* analysis ('UVA'; this is not a standard acronym), there is a single *dependent variable* (DV) that is *sampled* (measured), and one may be interested whether variations in sample measurements are associated with different conditions of interest. 'Samples' (or 'observations') do often have a time-element in them in the sense that one sample is acquired after the other, but that is not necessarily the case. For example:

- How many cars pass a certain bridge as a function of time of the day, where each sample is be the number of cars during a 5 minute time bin. This gives 144 samples per day.
- The number of worldwide tweets with hashtag ``#lol``, sampled per minute.
- The intensity for the light emitted at wavelengths between 4,000 and 4,100 Angstroms for a set of stars. Each star is a sample. 
- The Magnetoencephalography (MEG) signal from a SQUID (superconducting quantum interference device) magnetometer located above a participant head, while they are instructed indicate whether they detected a sound presented at near-threshold intensity. When the signal is sampled at 1kHz, a sample consists of the signal acquired during a 1 milisecond time bin.

- Spikes of a single neuron measured in macaque IT cortex during presentation of a series of images. A sample corresponds to the number of spikes measured while each image was presented, and there are as many samples as there were pictures.
- The Blood-Oxygen-Level Dependent (BOLD) signal averaged over a set of voxels in a region of interest in ventro-temporal cortex, while a participant's is brain sampled  at the same time they are viewing pictures of monkeys, lemurs, mallards, warblers, ladybugs and lunamoths. Each sample consists of the signal of that voxel during the acquisition of a single volume that takes 2 seconds to acquire. Data is acquired during ten 'runs' of 5 minutes each.

    + *or*: Estimates of responses to each of the categories, analyzed using a General Linear Model (GLM) for each run seperately. Each sample is based on a combination of run and stimulus category, yielding 6 * 10 = 60 samples. 
    + *or*: *t*-statistics of these responses, that take into account the variance of the residuals from the GLM. Again there are 60 samples.
 
In all cases these measurements can be represented by a *vector*, that is one-dimensional list of numbers. Each number refers to a single sample.

**MVPA**

In *multivariate* analysis, there are multiple *dependent variables* (DVs). In the terminology used in CoSMoMVPA these are called *features* (in *fMRI* they are often called *voxels*). This means that every sample has associated with one value per feature. Below is shown how the examples above could be translated to multivariate scenarios; note that the samples remain the same.

- Given a set of bridges all over the country, count the number of cars that pass each bridge. Bridges are the features.
- The number of worldwide tweets for a set of a hundred popular hashtags. Each hashtag is a feature.

     + *or*: for each country, the number of tweets with hashtag ``#lol``. The features are countries.
     + *or*: for each country and popular hashtag the number of worldwide tweets. Each unique pair of country and popular hashtag is a feature. This illustrates how data from different 'dimensions' (here the set of countries and the set of popular hashtags) can be crossed (combined) meaningfully. 
- Measure the intensity for wavelength bins from 1,000 to 8,000 Armstrongs in steps of 100 Armstrongs. Each wavelength bin is a feature.
- The signal across all SQUID magnetometers in an MEG system. Each magnetometer is a feature.
    + *or*: A Fourier transformation is applied to the signal of each magnetometer using a sliding window on the time series, yielding power estimates for a set of frequencies, for each magnetometer seperately. Each pair consisting of a magnetometer and frequency bin is a feature.
- The number of spikes measured across a group of neurons in IT cortex measured consecutively. Each neuron is a feature.
- The BOLD signal across all voxels in a region of interest, without averaging over voxels. Each voxel is a feature. This is unchanged in the situation when when response estimates or *t* statistics are used.

In theses cases the measurements can be presented by a matrix, that is a two-dimensional 'table' of numbers. If there are M samples and N features, the matrix is sized M x N (meaning it has M rows and N columns). 

- Each column represents the M measurements of all samples for one feature
- Each row represents the N measurements of all features for one sample. 

The univariate case described above is a special case, with N=1. 

**What is a 'pattern'?**

  * In **general**: It is a vector (or a list, if you like) containing the observations of features *for a single sample*
  * In **fMRI**: It is a vector of data over voxels for a single sample.
  * **CoSMoMVPA** uses the matrix representation described above; a pattern is represented by a row vector, or a row in a matrix.

In a simplistic and generic sense, MVPA includes any analysis where the outcome
is dependent on the variablility and/or consistency of measurements across a samples by features
matrix. As patterns contain more information than measurements of a single feature, answering the questions posed at the beginning of this section may be helped by the sensitivity provided by MVPA. 

**MATLAB** is an ideal environment for dealing with this sort of data with
hundreds of function for do MVPA analysis on rectangular matrices, some of which
you may be familiar with:

    * **corrcoef**: compute the pair-wise correlations for a set of column vectors
    * **cmdscale**: classic multidimensional scaling
    * **svmclassify / svmtrain**: support vector machine
    * **procrustes**: Procrustes transformation (used in `hyper-alignment <http://haxbylab.dartmouth.edu/ppl/swaroop.html>`_, )
    * and many many others ...

MVPA Dataset
++++++++++++

Given this general formulation, the remainder if this section will describe a framework that can be used to to MVPA in Matlab easily.
Inspired by PyMVPA_, the matrix representation above is expanded to form the concept of a *Dataset*, which does not only the sample-by-feature data matrix but also attributes associated with samples ('sample attributes'), features ('feature attributes'), or the whole dataset ('dataset attributes'). 

Attributes
++++++++++
Just the data in the sample-by-feature data matrix not sufficient to be able to perform analyses; typically one needs additional descriptors (or attributes) indicating what a sample or feature represents. In the Dataset representation used in CoSMoMVPA, there are three types of attributes:

- *sample attributes*: contain information about each sample (and is the same across all features). Most MVPA requires at least the following two sample attributes:

    * 'targets': represent the class of each sample. In the fMRI example above, these would be the category of the stimulus (monkeys, lemurs, mallards, warblers, ladybugs or lunamoths). In CoSMoMVPA, these are represented numerically; for example, 1=monkey, 2=lemur, ..., 6=lunamoth).
    * 'chunks': samples with the same chunks represent a group of samples that is acquired 'independently' from samples in other chunks. Independently is hard to define precisely, but in fMRI it usually refers to a single run of acquisition. In the fMRI example above, there are 10 chunks, each with 6 samples. In a take-one-out cross-validation analysis, for example, one tests a classifier on the samples in one chunk after it has been trained on the remaining chunks. 
    
- *feature attributes*: contain information about each feature (and is the same across all samples). These are optional, but some examples:

    * in fMRI: the voxel indices associated with each feature. With three spatial dimensions each feature is associated with three coordinates.
    * in MEEG: the label of the SQUID sensor.

- *dataset attributes*: contain general information about the whole dataset. For example, in fMRI, these could be:
    
    * the 'header' information containing information about the spatial layout (voxel size in each dimension, and the mapping from voxel indices to world coordinates. These are required to store data back to a file format that can be read by fMRI packages. 
    * the number of voxels in each dimensions. These are useful to determine voxel neighborhoods for searchlight analyses.

CoSMoMVPA Dataset
+++++++++++++++++
Taken the above together, a CoSMoMVPA dataset contains four ingredients: 'samples' (the sample x features data matrix), 'sample attributes', 'feature attributes', and 'dataset attributes'. These are implemented, in Matlab, using a ``struct``, with fields ``.samples``, ``.sa``, ``.fa``, and ``.a``. For example an fMRI dataset can be instantiated using :ref:`cosmo_fmri_dataset` and might look as follows:

    .. code-block:: matlab

              a: [1x1 struct]
             fa: [1x1 struct]
             sa: [1x1 struct]
        samples: [60x43822 double]
    
with ``.a``,

    .. code-block:: matlab

            hdr_nii: [1x1 struct]
            vol: [1x1 struct]

``.fa``,

    .. code-block:: matlab

            voxel_indices: [3x43822 double]

and ``.sa``:

        .. code-block:: matlab

            targets: [60x1 double]
            chunks: [60x1 double]

In this case there are M=60 samples and N=43822 features (voxels). Note that the sample attributes have M values in the first dimension, and feature attributes have N values in the second dimension. The information the ``.fa`` and ``.a`` fields is used when the dataset is back to a volumetric dataset in :ref:`cosmo_map2fmri`.

Datasets can also be 'sliced', i.e. subsets of either samples or targets can be selected, using `:ref:cosmo_slice`. Different datasets can be combined using `:ref:cosmo_stack`.

Classifier
++++++++++
Assume a dataset with samples, targets (class labels) and chunks; see above. A classifier can be used to test how well data in a subset of the data generalizes to another, disjoint, subset of the data. Usually this is done by taking some chunks as a test set, and use the remaining classes as a training set :ref:`cosmo_nchoosek_partitioner` , and its special case, :ref:`cosmo_nfold_partitioner`). Using a classifier takes two steps:

- train the classifier on the training set, providing it with the target labels for each sample in the training set.
- apply the classifier to the test set, without providing it with the target labels; rather it is asked to make a prediction for each sample of the test set.

Classification accuracy can be computed by considering how many samples in the test set were predicted, and this can be compared to what may be expected by chance. In the simple case where each chunk contains the same number of *n* samples in each class, change accuracy is *1/n*.

In CoSMoMVPA, all classifiers use the same signature:

    .. code-block:: matlab

        function predicted = cosmo_classify_lda(samples_train, targets_train, samples_test, opt)

where the first three parameters are self-explanatory, and the fourth parameter optional that may contain specific options to be used with a specific classifier. The output ``predicted`` contains the predicted class labels for each sample in ``samples_test``. Examples are :ref:`cosmo_classify_nn`, :ref:`cosmo_classify_svm`, :ref:`cosmo_classify_lda`, and :ref:`cosmo_classify_naive_bayes`. 

A classifier can be used for cross-validation using :ref:`cosmo_cross_validate`, or (see below), using a more abstract measure :ref:`cosmo_cross_validation_accuracy_measure`.

Measure
+++++++

 A dataset measure is a function with the following signature: 

    .. code-block:: matlab

        output = dataset_measure(dataset, args)

where ``dataset`` is a dataset of interest, and ``args`` are options specific for that measure. A measure can then be applied to either a dataset directly, or in combination with  a 'searchlight' where the measure is applied to each searchlight seperately. 
For example, the following code defines a 'measure' that returns classification accuracy based ona support vector machine classifier that uses n-fold cross-validation. The measure is then used in a searchlight with a radius of 3 voxels; the input is an fMRI dataset ``ds`` with chunks and targets set, the output an fMRI dataset with one sample containing classification accuracies.

    .. code-block:: matlab

        cv = @cosmo_cross_validation_accuracy_measure;
        cv_args = struct();
        cv_args.classifier = @cosmo_classify_svm;
        cv_args.partitions = cosmo_nfold_partitioner(ds);
        sl_dset = cosmo_searchlight(ds,cv,'args',cv_args,'radius',3);  


Using classifiers and measures in such an abstract way is a powerful approach to implement new analyses. Any function you write can be used as a dataset measure as long as it use the dataset measure input scheme, and can directly be used with (for example) a searchlight.

.. include:: links.rst

