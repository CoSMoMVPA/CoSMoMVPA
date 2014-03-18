.. _`cosmomvpa_concepts`: 

==================
CoSMoMVPA concepts
==================

.. contents::
    :depth: 2
    

.. _`cosmomvpa_dataset`: 

Dataset
^^^^^^^
Given the general formulation of *patterns* as used in MVPA, this section will describe a framework that can be used to to MVPA in Matlab easily. Inspired by PyMVPA_, the matrix representation of :ref:`patterns <mvpa_concepts>` is expanded to form the concept of a *Dataset*, which does not only the sample-by-feature data matrix but also attributes associated with samples ('sample attributes'), features ('feature attributes'), or the whole dataset ('dataset attributes'). A dataset in CoSMoMVPA can be visualized as follows:

.. figure:: _static/cosmo_dataset.png

A more detailed explanation is provided below.

Attributes
++++++++++
Just the data in the sample-by-feature data matrix not sufficient to be able to perform analyses; typically one needs additional descriptors (or attributes) indicating what a sample or feature represents. In the Dataset representation used in CoSMoMVPA, there are three types of attributes:

- *sample attributes*: contain information about each sample (and is the same across all features). Most MVPA requires at least the following two sample attributes:

    * ``.sa.targets``: represent the class of each sample. In the fMRI example above, these would be the category of the stimulus (monkeys, lemurs, ladybugs or lunamoths). In CoSMoMVPA, these are represented numerically; for example, 1=monkey, 2=lemur, 3=ladybug, 4=lunamoth).
    * ``.sa.chunks``: samples with the same chunks represent a group of samples that is acquired 'independently' from samples in other chunks. Independently is hard to define precisely, but in fMRI it usually refers to a single run of acquisition. In the fMRI example above, there are 10 chunks, each with 4 samples. In a take-one-out cross-validation analysis, for example, one tests a classifier on the samples in one chunk after it has been trained on the samples in the remaining chunks. 

    Note that in the example here there is a third sample attribute, ``.sa.labels``, which is a cell containing human-readable descriptions of each sample.
    
- *feature attributes*: contain information about each feature (and is the same across all samples). These are optional in principal, but in most use cases these are used to specify information where the feature came from.

    * in fMRI: the voxel indices associated with each feature. With three spatial dimensions each feature is associated with three indices, ``.fa.i``, ``.fa.j``, and ``.fa.k``.     
    * in MEEG: the indices of SQUID sensor, time-point, or frequency band. For example, data transformed to time-frequency space has three feature attributes: ``.fa.chan``, ``.fa.time``, and ``.fa.freq``.

- *dataset attributes*: contain general information about the whole dataset. 

    In fMRI these are typically:
    
    * the 'header' information containing information about the spatial layout (voxel size in each dimension, and the mapping from voxel indices to world coordinates). These are required to store data back to a file format that can be read by fMRI packages. 
    * The range of indices used in ``.fa.i``, ``.fa.j`` and ``.fa.k``, stored in ``.a.dim.values``.
    * The names of the spatial feature attributes, stored in ``.a.dim.labels``.

    In MEEG these are, for a dataset with data in time-frequency space:

    * The names of the feature attribtues ( ``chan``, ``time``, and ``freq``), stored in ``.a.dim.labels`` . 
    * SQUID channel names are stored in the field ``.a.dim.values{1}``, time-points in ``.a.dim.values{2}``, and frequencies in ``.a.dim.values{3}``.

Targets
+++++++
The example above showed the sample attribute ``targets``, and its use is not by accident. As for almost all MVPA applications one is interested in the (dis)similarity of patterns within and across *conditions of interest*, these should be stored in the dataset. Here, conditions of interest is typically defined by the experimental paradigm, for example:

    * category of visual stimulus: house, face, or human body.
    * effector involved in movement planning: left hand or right hand.
    * whether a peri-threshold auditory stimulus was perceived: yes or no.

In CoSMoMVPA_ these conditions are coded in a special *sample attribute* called *targets*, i.e. in a dataset ``ds`` they are in ``ds.sa.targets``. They should be coded as integer values in a ``Px1`` vector, where ``P`` is the number of samples. 

Chunks
++++++
Another sample attribute illustrated above (that is also important for most MVPA applications) is the concept of *chunks*. Here, a *chunk* is meant to indicate a set of samples that can be considered **independent** from samples in other chunks, whereas samples within a chunk are not necessarily independent. 

Independency is crucial here, because many core MVP analyses assess generalizability of pattern properties of a subset of chunks to another disjoint subset of chunks. For example,
    * in split-half correlation analysis, the data is split in two and each half assigned to a different chunk, yielding two chunks. A typical application is computing 'on-diagonal' vs 'off-diagonal' correlations, i.e. the difference of pattern correlations of the same target versus other targets. 
    * in an ``n``-fold cross-validation scheme, the data is split in ``n`` chunks. A typical application is cross-validated classification, where a classifier is tested on one chunk after being trained on the remaining chunks. 

Typical chunk assignments are:
    * in fMRI studies: each run (period of continuous recording) gives rise to a single chunk. Putting samples in a single run in different chunks may violate the independency assumption because of the slow-ness of the BOLD response, unless samples are seperated by a considerable time interval. 
    * in MEEG studies: if trials can be assumed to be independent then chunks can be assigned randomly (or in a systematic order). Otherwise they should also be assigned on a run-by-run basis.

As with *targets* above, *chunks* should be coded as integer values in a ``Px1`` vector, where ``P`` is the number of samples. 


Samples + sample attributes + feature attributes + dataset attributes = dataset
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Taken the above together, a CoSMoMVPA dataset contains four ingredients: 'samples' (the sample x features data matrix), 'sample attributes', 'feature attributes', and 'dataset attributes'. These are implemented, in Matlab, using a ``struct``, with fields ``.samples``, ``.sa``, ``.fa``, and ``.a``. For example an fMRI dataset can be instantiated using :ref:`cosmo_fmri_dataset` and might look as follows:

    .. code-block:: matlab

        samples: [40x43822 double]
              a: [1x1 struct]
             fa: [1x1 struct]
             sa: [1x1 struct]

with ``.sa``,

        .. code-block:: matlab


            targets: [40x1 double]
             chunks: [40x1 double]
             labels: {40x1 cell}


``.fa``,

    .. code-block:: matlab


            i: [1x43822 double]
            j: [1x43822 double]
            k: [1x43822 double]


and ``.a``.

    .. code-block:: matlab

            
            dim: [1x1 struct]
            hdr_nii: [1x1 struct]


In this case there are M=40 samples and N=43822 features (voxels). Note that the sample attributes have M values in the first dimension, and feature attributes have N values in the second dimension. The information in the ``.fa`` and ``.a`` fields is used when the dataset is back to a volumetric dataset in :ref:`cosmo_map2fmri`.

Datasets can also be 'sliced', i.e. subsets of either samples or targets can be selected, using :ref:`cosmo_slice`. A special case is :ref:`cosmo_split`, which splits a dataset based on unique values of sample- or feature attributes. Different datasets, assuming their feature or sample attributes are identical, can be combined using :ref:`cosmo_stack`.

.. _`cosmomvpa_classifier`: 

Classifier
^^^^^^^^^^
Assume a dataset with samples, targets (class labels) and chunks; see above. A classifier can be used to test how well data in a subset of the data generalizes to another, disjoint, subset of the data. Usually this is done by taking some chunks as a test set, and use the remaining classes as a training set :ref:`cosmo_nchoosek_partitioner` , and its special case, :ref:`cosmo_nfold_partitioner`). Using a classifier takes two steps:

- train the classifier on the training set, providing it with the target labels for each sample in the training set.
- apply the classifier to the test set, without providing it with the target labels; rather it is asked to make a prediction for each sample of the test set.

Classification accuracy can be computed by considering how many samples in the test set were predicted, and this can be compared to what may be expected by chance. In the simple case where each chunk contains the same number of *n* samples in each class, change accuracy is *1/n*.

In CoSMoMVPA, all classifiers use the same signature:

    .. code-block:: matlab

        function predicted = cosmo_classify_lda(samples_train, targets_train, samples_test, opt)

where the first three parameters are self-explanatory, and the fourth parameter is optional and may contain specific options to be used with a specific classifier. The output ``predicted`` contains the predicted class labels for each sample in ``samples_test``. Examples are :ref:`cosmo_classify_nn`, :ref:`cosmo_classify_svm`, :ref:`cosmo_classify_lda`, and :ref:`cosmo_classify_naive_bayes`. 

A classifier can be used for cross-validation using :ref:`cosmo_crossvalidate`, or (see below), using a more abstract measure :ref:`cosmo_crossvalidation_measure`.

.. _`cosmomvpa_measure`: 

Measure
^^^^^^^

 A dataset measure is a function with the following signature: 

    .. code-block:: matlab

        output = dataset_measure(dataset, args)

where ``dataset`` is a dataset of interest, and ``args`` are options specific for that measure. A measure can then be applied to either a dataset directly, or in combination with  a 'searchlight' where the measure is applied to each searchlight seperately. The output should be in the column vector format (a scalar satisfies this requirement).

For example, the following code defines a 'measure' that returns classification accuracy based ona support vector machine classifier that uses n-fold cross-validation. The measure is then used in a searchlight with a radius of 3 voxels; the input is an fMRI dataset ``ds`` with chunks and targets set, the output an fMRI dataset with one sample containing classification accuracies.

    .. code-block:: matlab

        cv = @cosmo_cross_validation_accuracy_measure;
        cv_args = struct();
        cv_args.classifier = @cosmo_classify_svm;
        cv_args.partitions = cosmo_nfold_partitioner(ds);
        sl_dset = cosmo_searchlight(ds,cv,'args',cv_args,'radius',3);  


Using classifiers and measures in such an abstract way is a powerful approach to implement new analyses. Any function you write can be used as a dataset measure as long as it use the dataset measure input scheme, and can directly be used with (for example) a searchlight.

.. include:: links.txt

