.. _download: 

=====================
Download instructions
=====================

CoSMoMVPA code
++++++++++++++
The latest code is available from GitHub_. As this code is under development, it may change rapidly.

- `git` users can clone the repository: ``git clone https://github.com/CoSMoMVPA/CoSMoMVPA.git``.

- Others can download and extract the `zip archive`_.

Note: when CoSMoMVPA is released officially, there will be permanent links, hosted on the website, containing official, feature-stable, releases.

External dependencies
+++++++++++++++++++++
Certain functionality require certain external toolboxes: 

- BrainVoyager_ files require NeuroElf_ toolbox.
- AFNI_ files require the ``AFNI Matlab`` library.
- the Support Vector Machine (SVM) classifier requires the `Matlab statistics`_ toolbox.
- MEEG data requires FieldTrip_ for almost all MEEG-related functions.

Tutorial data
+++++++++++++
Tutorual data is currently not ready for public release yet. Once it is ready we will update the information here.

Developers
++++++++++
If you want to contribute, please see :ref:`contribute`. 

Our current build system only supports `Unix-like`_ systems, and dependencies include Sphinx_ and Python_. 

Unit tests require the xUnit_ toolbox.

.. include:: links.rst
