.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

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

.. include:: verify_exercise_setup.txt

For the patient
+++++++++++++++


The Matlab / Octave code (in ``mvpa/``) is required for analyses in CoSMoMVPA_; the example data (in ``examples``) is required to run the :ref:`exercises <rhul2016>` and the :ref:`demos <contents_demo.rst>`.

* Installation of CoSMoMVPA:

    - Users on a Unix-like (Linux, OSX) platform using the command line::

            git clone https://github.com/CoSMoMVPA/CoSMoMVPA.git
            make -C CoSMoMVPA install

    - Manually:

        + Download the `zip archive`_.

        +  Add the source code directories to the Matlab_ / Octave_ path, by changing the directory to the CoSMoMVPA_ ``/mvpa`` directory, then run:

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

* Get the tutorial data:

    Download the `tutorial data <http://cosmomvpa.org/datadb.zip>`_ zip archive, and unzip it.

    For a minimal set of data (only fMRI AK6 data for the exercises), consider using  `tutorial data with AK6 data only <http://cosmomvpa.org/datadb-ak6.zip>`_

    You can move the directory to another location on your file system, if desired.


.. _`set_cosmovmpa_cfg`:

* Set the location of the tutorial data in a text file named ``.cosmomvpa.cfg`` (in a directory that is in the matlab path), as described in the *Notes* section of :ref:`cosmo_config_hdr`.

    + Use ``cosmo_wizard_set_config`` in CoSMoMVPA's ``examples/`` directory, if you prefer a simple-to-use graphical user interface.

    + To do so manually:

         * If you do not know where to store the file, just close and start Matlab afresh (so that it starts in a location that is in the Matlab path), and run

                .. code-block:: matlab

                    edit .cosmomvpa.cfg

            Alternatively, go to CoSMoMVPA's ``mvpa/`` directory and store the ``.cosmomvpa.cfg`` file there (the disadvantage of this location is that the file may be lost if code is updated by downloading an updated ``.zip``-file).

          * Note for Windows users: when creating a new file, Windows may add (but hide) a ``.txt`` extension. It may be better to edit the file from Matlab.

          * Note for Unix (OSX, Linux) users: the file can be stored in the users' ``$HOME`` directory.

          * Note for Unix (OSX, Linux) users: the file will not be shown in the terminal when using ``ls``, because the leading dot in the filename makes it hidden. To show hidden files, use ``ls -a``.

          * Add the lines for ``tutorial_data_path`` and ``output_data_path``, and save the file.

          * For example, on Apple OSX ``.cosmomvpa.cfg`` could be stored in the ``/Users/karen`` home directory (for a user named ``karen``), and contain the following:

              .. code-block:: none

                  tutorial_data_path=/Users/karen/datasets/CoSMoMVPA/datadb/tutorial_data
                  output_data_path=/Users/karen/tmp/CoSMoMVPA_output

      You can choose in which directory you would like to store the output for from running the examples and demonstrations; just make sture that the ``output_data_path`` directory exists. You can create a new directory for the output if you want.

.. _`test_local_setup`:

.. include:: verify_exercise_setup.txt

.. _`keep_code_up_to_date`:

^^^^^^^^^^^^^^^^^^^^^^^^^
Keep your code up to date
^^^^^^^^^^^^^^^^^^^^^^^^^

CoSMoMVPA_ code may change rapidly. To stay up to date:

* ``git`` users (assuming you followed the :ref:`instructions to get the code <get_code_and_example_data>`)::

    git checkout master
    git pull origin master

* everybody else: you would have to re-download the `zip archive`_ and update your local ``.m`` files. (At the moment we do not provide automatic detection of code that is out of date.)


External dependencies
+++++++++++++++++++++
Certain functionality require certain external toolboxes:

- BrainVoyager_ files require NeuroElf_ toolbox.
- AFNI_ files require the ``AFNI Matlab`` library.
- Matlab_'s Support Vector Machine (SVM) classifier (accessed through :ref:`cosmo_classify_svm`), and some other functions that use statistical computations, require the `Matlab statistics`_ toolbox.
- LIBSVM_'s Support Vector Machine (SVM) classifier (accessed through  :ref:`cosmo_classify_libsvm`) requires the LIBSVM_ toolbox.
- MEEG data requires FieldTrip_ for almost all MEEG-related functions.
- On Octave_, the ``io``, ``nan``, ``statistics``, ``miscellaneous`` and ``general`` are required; they are available from `Octave-Forge`_. See :ref:`here <get_octave_packages>` for details.

For operations that require external toolboxes, CoSMoMVPA_ will check their presence. If a required external toolbox is not available, an error message is given with download instructions.

.. _download_tutorial_data:

Developers
++++++++++
Contributions are welcomed! Please see :ref:`contribute`.

We use a build system for generating documentation. This build system only supports `Unix-like`_ systems, and dependencies include Sphinx_, Python_, and `sphinxcontrib-matlabdomain`_. For details see :ref:`building the documentation`.

Unit tests require either the xUnit_ or MOxUnit_ toolbox and run on both Matlab_ and Octave_. Doc tests are currently only supported for xUnit_, which only runs on Matlab_ (not on Octave_). MOxUnit_ does not support doc tests because Octave_ does not support the ``evalc`` command.

.. include:: links.txt
