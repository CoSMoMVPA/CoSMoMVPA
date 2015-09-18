.. _download:

=====================
Download instructions
=====================


.. _`get_code_and_example_data`:

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Get the code and example data
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For the impatient
+++++++++++++++++

.. include:: quick_download.txt

For the patient
+++++++++++++++


The Matlab / Octave code (in ``mvpa/``) is required for analyses in CoSMoMVPA_; the example data (in ``examples``) is required to run the :ref:`exercises <cimec2014>` and the :ref:`demos <contents_demo.rst>`.

* Get the CoSMoMVPA_ source code:

    + ``git`` users::

        git clone https://github.com/CoSMoMVPA/CoSMoMVPA.git

    + everybody else: download the `zip archive`_.

* Add the source code directories to the Matlab_ / Octave_ path, by changing the directory to the CoSMoMVPA_ ``/mvpa`` directory, then running

    .. code-block:: matlab

        cosmo_set_path

    (alternatively, add the ``mvpa`` and ``external`` directories, and their subdirectories to the path).

    Then run

    .. code-block:: matlab

        savepath

    to store the new path permanently.

    To check that things are working, run:

    .. code-block:: matlab

        cosmo_wtf

    which should provide a report of available system information.

.. _`get_octave_packages`:

* (Matlab_ users can skip this step) For users of Octave_, some additional packages from `Octave-Force` are required. First run the following from the Octave prompt:

    .. code-block:: matlab

        pkg install -forge io
        pkg install -forge nan
        pkg install -forge statistics
        pkg install -forge general
        pkg install -forge miscellaneous

    To activate these packages, run the following commands:

    .. code-block:: matlab

        pkg load io
        pkg load nan
        pkg load statistics
        pkg load general
        pkg load miscellaneous


    To load these packages automatically when Octave is started, it is recommended to add the following *at the end* of the ``.octaverc`` file (which is typically located in the user's home directory). Note that the first command switches off the ``more`` program for viewing output, so that all output is show directly in the command window:

    .. code-block:: matlab

        more off
        pkg load io
        pkg unload nan
        pkg load nan
        pkg load statistics
        pkg load miscellaneous
        pkg load general


.. _`get_tutorial_data`:

* Download the tutorial data:

    - Standard approach: download the `tutorial data <http://cosmomvpa.org/datadb.zip>`_ zip archive, and unzip it.
    - Advanced Unix users: ``cd`` to the CoSMoMVPA directory, then run::

        wget http://cosmomvpa.org/datadb.zip && unzip datadb.zip && rm datadb.zip

    You can move the directory to another location on your file system, if desired.


.. _`set_cosmovmpa_cfg`:

* Set the location of the tutorial data in a text file named ``.cosmomvpa.cfg`` (in a directory that is in the matlab path), as described in the *Notes* section of :ref:`cosmo_config_hdr`.

    + If you do not know where to store the file, just close and start Matlab afresh (so that it starts in a location that is in the Matlab path), and run

        .. code-block:: matlab

            edit .cosmomvpa.cfg

        Then add the lines for ``tutorial_data_path=`` and ``output_data_path``, and save the file.

.. _`test_local_setup`:

* To verify that everything works, run the following in Matlab:

    .. code-block:: matlab

        config=cosmo_config();
        data_path=fullfile(config.tutorial_data_path,'ak6','s01');
        ds=cosmo_fmri_dataset(fullfile(data_path,'vt_mask.nii'),'mask',true);
        cosmo_map2fmri(ds,fullfile(config.output_data_path,'test.nii'));

    (Running these commands may give a warning message ``flip_orient field found``, which can safely be ignored.)

    If no errors are raised and a file ``test.nii`` is created in the output_data_path, then you are good to go.

.. _`keep_code_up_to_date`:

^^^^^^^^^^^^^^^^^^^^^^^^^
Keep your code up to date
^^^^^^^^^^^^^^^^^^^^^^^^^

CoSMoMVPA_ code may change rapidly. To stay up to date:

* ``git`` users (assuming you followed the :ref:`instructions to get the code <get_code_and_example_data>`)::

    git checkout master
    git pull origin master

* everybody else: you would have to re-download the `zip archive`_ and update your local Matlab files. (At the moment we do not provide automatic detection of code that is out of date.)


External dependencies
+++++++++++++++++++++
Certain functionality require certain external toolboxes:

- BrainVoyager_ files require NeuroElf_ toolbox.
- AFNI_ files require the ``AFNI Matlab`` library.
- Matlab_'s Support Vector Machine (SVM) classifier (accessed through :ref:`cosmo_classify_svm`), and some other functions that use statistical computations, require the `Matlab statistics`_ toolbox.
- LIBSVM_'s Support Vector Machine (SVM) classifier (accessed through  :ref:`cosmo_classify_libsvm`) requires the LIBSVM_ toolbox.
- MEEG data requires FieldTrip_ for almost all MEEG-related functions.

    + GNU Octave users: consider using our `FieldTrip branch with improved GNU Octave compatibility`_.


- On Octave_, the ``io``, ``nan``, ``statistics``, ``miscellaneous`` and ``general`` are required; they are available from `Octave-Forge`_. See :ref:`here <get_octave_packages>` for details.

For operations that require external toolboxes, CoSMoMVPA_ will check their presence. If a required external toolbox is not available, an error message is given with download instructions.

.. _download_tutorial_data:

Developers
++++++++++
Contributions are welcomed! Please see :ref:`contribute`.

We use a build system for generating documentation. This build system only supports `Unix-like`_ systems, and dependencies include Sphinx_, Python_, and `sphinxcontrib-matlabdomain`_. For details see :ref:`building the documentation`.

Unit tests require either the xUnit_ or MOxUnit_ toolbox and run on both Matlab_ and Octave_. Doc tests are currently only supported for xUnit_, which only runs on Matlab_ (not on Octave_). MOxUnit_ does not support doc tests because Octave_ does not support the ``evalc`` command.

.. include:: links.txt
