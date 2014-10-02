.. _`get started`:

===========
Get Started
===========


.. toctree::
    :maxdepth: 1
    :titlesonly:

    download
    matlab_experience
    cogneuro_experience
    mvpa_concepts
    cosmomvpa_concepts

^^^^^^^^^^^^^
Prerequisites
^^^^^^^^^^^^^

Using CoSMoMVPA_ effectively requires:

- a working installation of Matlab_.
- the CoSMoMVPA Matlab source code
- optionally the tutorial data, available :ref:`here <download>` (to run the :ref:`exercises <ex_toc>`).
- optionally some external toolboxes for AFNI, BrainVoyager, and/or FieldTrip file support; see :ref:`here <download>`.
- an :ref:`advanced beginner level <matlab_experience>` of experience in Matlab programming.
- an :ref:`advanced beginner level <cogneuro_experience>` of fMRI or MEEG data analysis.
- a basic understanding of :ref:`MVPA concepts <mvpa_concepts>`.
- familiarity with :ref:`CoSMoMVPA concepts <cosmomvpa_concepts>`, in particular the :ref:`cosmomvpa_dataset`, :ref:`cosmomvpa_targets`, :ref:`cosmomvpa_chunks`, :ref:`cosmomvpa_classifier`, :ref:`cosmomvpa_neighborhood`, and :ref:`cosmomvpa_measure` concepts.

Consider the :ref:`demos <contents_demo.rst>` to see how MVPA can be performed using CoSMoMVPA_.

.. _`get_code_and_example_data`:

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Get the code and example data
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The Matlab code is required for analyses in CoSMoMVPA_; the example data is required to run the exercises and the :ref:`demos <contents_demo.rst>`.

* First, get both the source code and the example data:

    - the CoSMoMVPA Matlab source code:

        + ``git`` users::

            git clone https://github.com/CoSMoMVPA/CoSMoMVPA.git

        + everybody else: download the `zip archive`_.

    - the tutorial data, available :ref:`here <download_tutorial_data>`. Unzip the archive and put the data in a directory of choice

* Add the CoSMoMVPA directories to your path, by running

    .. code-block:: matlab

        cosmo_set_path

    followed by

    .. code-block:: matlab

        save_path

    to store the new path permanently.

* Set the location of the tutorial data in a text file named ``.cosmomvpa.cfg`` (in a directory that is in the matlab path), as described in the *Notes* section of :ref:`cosmo_config_hdr`. 

    + If you do not know where to store the file, just close and start Matlab afresh (so that it starts in a location that is in the Matlab path), and run

        .. code-block:: matlab

            edit .cosmomvpa.cfg

Then add the lines for ``tutorial_data_path=`` and ``output_data_path``, and save the file.

* To verify that everything works, run the following in Matlab:

    .. code-block:: matlab

        config=cosmo_config();
        data_path=fullfile(config.tutorial_data_path,'ak6','s01');
        ds=cosmo_fmri_dataset(fullfile(data_path,'vt_mask.nii'));
        cosmo_map2fmri(ds,fullfile(config.output_data_path,'test.nii'));


If no errors are raised and a file ``test.nii`` is created in the output_data_path, then you are good to go.


^^^^^^^^^^^^^^^^^^^^^^^^^
Keep your code up to date
^^^^^^^^^^^^^^^^^^^^^^^^^

CoSMoMVPA_ code may change rapidly. To stay up to date:

* ``git`` users (assuming you followed the :ref:`instructions to get the code <get_code_and_example_data>`)::

    git checkout master
    git pull origin master

* everybody else: you would have to re-download the `zip archive`_ and update your local Matlab files. (At the moment we do not provide automatic detection of code that is out of date.)

^^^^^^^^^^
Next steps
^^^^^^^^^^

Once you are ready:

- run the :ref:`demos <contents_demo.rst>`.
- look at the :ref:`runnable examples <modindex_run>` and the associated `Matlab outputs`_.
- try the :ref:`exercises <ex_toc>`.
- explore the :ref:`CoSMoMVPA functions <modindex>`.


.. include:: links.txt

.. _Matlab outputs: _static/publish/index.html

