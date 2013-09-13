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

There is currently no support for *MEEG*.

Understanding CoSMoMVPA concepts
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

