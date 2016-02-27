.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`mvpa_concepts`:

=============================
Multivariate pattern analysis
=============================

Understanding the basic concept of a *pattern*, as used in *multivariate pattern analysis*, is crucial for using CoSMoMVPA. This section introduces this concept gently.

Multivariate pattern analysis (MVPA)
++++++++++++++++++++++++++++++++++++

Before diving into MVPA, let's consider a series of example questions that one might be interested in:

- Does gas price affect how much people use their car?
- Are the topics of tweets affected by the Dow Jones index?
- Where in the brain are categorical similarities of animal species represented?
- Does whether a person hears a sound or not depend on his brain state *before* the sound was presented?
- Can brain responses associated with viewing different pictures be explained by measurements of single neurons?

Although in the age of truthiness one may have intuitive reponses to these questions, a more scientific approach entails collecting data to see if an association can be found between effects of interest. MVPA can help by providing a sensitive analysis tool to address these and many other questions.

First we present a general case to explain how MVPA can be applied to a wide variety of cases; then we focus towards applying this to fMRI analysis.

Starting simple: the univariate case
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

More measurements: the multivariate case
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

Patterns
^^^^^^^^
What is a 'pattern'? There are multiple answers, depending on the context:

  * In **general**: It is a vector (or a list, if you like) containing the observations of features *for a single sample*
  * In **fMRI**: It is a vector of data over voxels for a single sample.
  * **CoSMoMVPA** uses the matrix representation described above; a pattern is represented by a row vector, or a row in a matrix.

In a simplistic and generic sense, MVPA includes any analysis where the outcome
is dependent on the variablility and/or consistency of measurements across a samples by features
matrix. As patterns contain more information than measurements of a single feature, answering the questions posed at the beginning of this section may be helped by the sensitivity provided by MVPA.

**MATLAB** is an ideal environment for dealing with this sort of data with
hundreds of function for do MVPA analysis on rectangular matrices, some of which
you may be familiar with:

    * ``corrcoef``: compute the pair-wise correlations for a set of column vectors
    * ``cmdscale``: classic multidimensional scaling
    * ``svmclassify / svmtrain``: support vector machine
    * ``procrustes``: Procrustes transformation (used in `hyper-alignment <http://haxbylab.dartmouth.edu/ppl/swaroop.html>`_, )
    * and many many others ...

Further reading
^^^^^^^^^^^^^^^
For additional concepts see :ref:`CoSMoMVPA concepts <cosmomvpa_concepts>`.

