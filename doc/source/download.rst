.. _download: 

=====================
Download instructions
=====================

CoSMoMVPA code
++++++++++++++
The latest code is available from GitHub_. As this code is under development, it may change rapidly.

- `git` users can clone the repository:: 

    git clone https://github.com/CoSMoMVPA/CoSMoMVPA.git

   To update an already existing repository (i.e. after the clone), run::

    git checkout master
    git pull origin master

- Others can download and extract the `zip archive`_.

To use CoSMoMVPA_ in Matlab_, run ``cosmo_set_path`` followed by ``savepath``. Alternatively you can manually add the ``mvpa`` and ``external`` directories (and their subdirectories) to the Matlab path.

Note: when CoSMoMVPA is released officially, there will be permanent links, hosted on the website, containing official, feature-stable, releases.

External dependencies
+++++++++++++++++++++
Certain functionality require certain external toolboxes: 

- BrainVoyager_ files require NeuroElf_ toolbox.
- AFNI_ files require the ``AFNI Matlab`` library.
- Matlab_'s Support Vector Machine (SVM) classifier (accessed through :ref:`cosmo_classify_svm`), and some other functions that use statistical computations, require the `Matlab statistics`_ toolbox.
- LIBSVM_'s Support Vector Machine (SVM) classifier (accessed through  :ref:`cosmo_classify_libsvm`) requires the LIBSVM_ toolbox.
- MEEG data requires FieldTrip_ for almost all MEEG-related functions.

Tutorial data
+++++++++++++
The tutorial data can be downloaded in the following ways:

- Standard approach: download the `tutorial data <http://cosmomvpa.org/datadb.zip>`_ zip archive, unzip it, and move the ``datadb`` directory to the CoSMoMVPA root directory. 

- more advanced Unix users: ``cd`` to the CoSMoMVPA directory, then run::

    wget http://cosmomvpa.org/datadb.zip && unzip datadb.zip && rm datadb.zip

The tutorial data can also be stored elsewhere; to do so, specify it in a ``.cosmomvpa.cfg`` configuration file as decribed in the *Notes* section of :ref:`cosmo_config_hdr`.

Developers
++++++++++
Contributions are welcomed! Please see :ref:`contribute`. 

Our current build system only supports `Unix-like`_ systems, and dependencies include Sphinx_, Python_, and `sphinxcontrib-matlabdomain`_. For details see `building the documentation`_.

Unit tests require the xUnit_ toolbox.

.. include:: links.txt
