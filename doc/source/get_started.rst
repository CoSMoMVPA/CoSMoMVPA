.. _`get started`: Ge   t started

===========
Get Started
===========


Prerequisites
^^^^^^^^^^^^^

CoSMoMVPA_ requires:

- a working installation of Matlab_.
- the CoSMoMVPA Matlab code, and optionally external toolboxes for additional functionality. You can download_ these.
- An advanced beginner level of Matlab programming (see below)
- An advanced beginner level of cognitive neuroscience (fMRI) data analysis (see below)

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

(The no idea what an expert user should be able to do, because we don't consider ourselves in that category).

Cogntive neuroscience experience
++++++++++++++++++++++++++++++++
This is not a tutorial on how to preprocess cognitive neuroscience data; it is assumed that the user is already familiar with these. 

For *fMRI* users should:

- be able to preprocess data (e.g. motion correction, slice time correction, signal normalization). 
- be able to create a mask of either the whole brain or regions of interest.
- be able to run the General Linear Model to get beta estimates and t-statistics.

There is currently no support for *MEEG*, although we hope to add it in the future.

Understanding CoSMoMVPA concepts
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

There are a few concepts used in CoSMoMVPA that may require some explanation: datasets, classifiers, and measures.

Multivariata pattern analysis (MVPA)
++++++++++++++++++++++++++++++++++++

Before diving into MVPA, let's consider a series of example questions that one might be interested in:

- Does gas price affect how much people use their car?
- Do people laugh more when the Dow Jones index is higher?
- Where in the brain are categorical similarities of animal species represented?
- Does whether a person hears a sound or not depend on his brain state *before* the sound was presented?
- Can brain responses associated with viewing different pictures be explained by measurements of single neurons?

Although in the age of truthiness one may have intuitive reponses to these questions, a more scientific approach entails collecting data to see if an association can be found between effects of interest. MVPA can help by providing a sensitive analysis tool to address these and many other questions.

**'UVA'**

Taking one step back, in *univariate* analysis ('UVA'; this is not a standard acronym), there is a single *dependent variable* (DV) that is *sampled* (measured), and one may be interested whether variations in sample measurements are associated with different conditions of interest. Samples do often have a time-element in them in the sense that one sample is acquired after the other, but that is not necessarily the case. For example:

- How many cars pass a certain bridge as a function of time of the day, where each sample is be the number of cars during a 5 minute time bin. This gives 144 samples per day.
- The number of worldwide tweets with hashtag ``#lol``, sampled per minute.
- Measure the intensity for the light emitted at wavelengths between 4,000 and 4,100 Angstroms for a set of stars. Each star is a sample. 
- The Blood-Oxygen-Level Dependent (BOLD) signal in a voxel in a participants brain sampled using fMRI, while participants views pictures of monkeys, lemurs, mallards, warblers, ladybugs and lunamoths. Each sample consists of the signal of that voxel during the acquisition of a single volume that takes 2 seconds to acquire. Data is acquired during five 'runs' of 5 minutes each.

    + *or*: Estimates of responses to each of the categories, analyzed using a General Linear Model (GLM) for each run seperately. Each sample is based on a combination of run and stimulus category, yielding 6 * 5 = 30 samples. 
    + *or*: *t*-statistics of these responses, that take into account the variance of the residuals from the GLM. Again there are 30 samples.
    
- The Magnetoencephalography (MEG) signal from a SQUID (superconducting quantum interference device) magnetometer located above a participant head, while they are instructed indicate whether they detected a sound presented at near-threshold intensity. When the signal is sampled at 1kHz, a sample consists of the signal acquired during a 1 milisecond time bin.

- Spikes of a single neuron measured in macaque IT cortex during presentation of a series of images. A sample corresponds to the number of spikes measured while each image was presented, and there are as many samples as there were pictures.


**MVPA**

In *multivariate* analysis, there are multiple *dependent variables* (DVs). In the terminology used in CoSMoMVPA these are called *features*. This means that every sample has associated with one value per feature. Below is shown how the examples above could be translated to multivariate scenarios; note that the samples remain the same.

- Given a set of bridges all over the country, count the number of cars that pass each bridge. Bridges are the features.
- The number of worldwide tweets for a set of a hundred popular hashtags. Each hashtag is a feature.

     + *or*: for each country, the number of tweets with hashtag ``#lol``. The features are countries.
     + *or*: for each country and popular hashtag the number of worldwide tweets. Each unique pair of country and popular hashtag is a feature. This illustrates how data from different 'dimensions' (here the set of countries and the set of popular hashtags) can be crossed (combined) meaningfully. 

- Measure the intensity for wavelength bins from 1,000 to 8,000 Armstrongs in steps of 100 Armstrongs. Each wavelength bin is a feature.

- The BOLD signal across all voxels in a participants brain. Each voxel is a feature. This is also the case when response estimates or *t* statistics are used.

     + *or*: the BOLD signal of all voxels in a small region of interest somewhere in the brain. Each voxel in the region of interest is a feature, but the number of features is much smaller than for the whole brain scenario.

- The signal across all SQUID magnetometers in an MEG system. Each magnetometer is a feature.

    + *or*: A Fourier transformation is applied to the signal of each magnetometer using a sliding window on the time series, yielding power estimates for a set of frequencies, for each magnetometer seperately. Each pair consisting of a magnetometer and frequency bin is a feature.

- The number of spikes measured across a group of neurons in IT cortex measured consecutively. Each neuron is a feature.

**What is a 'pattern'?**

  * In **general**: It is a vector (or a list, if you like) containing the observations of features *for a single sample*.
  * In **fMRI**: It is a vector of data over voxels for a single sample.
  * In **CoSMoMVPA**, i.e., in **MATLAB**: It is represented by a row vector, or a row in a matrix.

XXX TODO a lot more from here.


A dataset is a set of patterns over the same features that are vertically
stacked on one another into a 2-D N x M matrix with N patterns and M features.
Patterns are sometimes called "observations" or "samples".  In this tutorial we
will call them samples.

In a simplistic and generic sense, MVPA includes any analysis where the outcome
is dependent on the variablility of measurements across a a samples by features
matrix.

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

Given this general formulation, our workshop will aim to build a foundation and
a working MATLAB toolbox for MVP analysis around the **dataset** as a common
starting point. For this we have adopted the terminology and many of the
semantics of the `PyMVPA <http://www.pymvpa.org/>`_ Python library which you are
encouraged to learn more about especially if you interesting in learning to
program in `Python <http://www.python.org/>`_.



Chunks and classes
++++++++++++++++++


Dataset
+++++++

TODO




Classifier
++++++++++

TODO

Measure
+++++++

TODO

.. include:: links.rst

