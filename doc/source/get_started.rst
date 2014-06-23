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
- the CoSMoMVPA Matlab source code:

    + ``git`` users:: 

        git clone https://github.com/CoSMoMVPA/CoSMoMVPA.git

    + alternatively, download the `zip archive`_.

  In Matlab_, run ``cosmo_set_path`` followed by ``savepath``. Alternatively one can manually add the ``mvpa`` and ``external`` directories (and their subdirectories) to the Matlab path.
- optionally the tutorial data, available :ref:`here <download>` (to run the :ref:`exercises <ex_toc>`).
- optionally some external toolboxes for AFNI, BrainVoyager, and/or FieldTrip file support; see :ref:`here <download>`.
- an :ref:`advanced beginner level <matlab_experience>` of experience in Matlab programming.
- an :ref:`advanced beginner level <cogneuro_experience>` of fMRI or MEEG data analysis.
- a basic understanding of :ref:`MVPA concepts <mvpa_concepts>`.
- familiarity with :ref:`CoSMoMVPA concepts <cosmomvpa_concepts>`, in particular the :ref:`cosmomvpa_dataset`, :ref:`cosmomvpa_targets`, :ref:`cosmomvpa_chunks`, :ref:`cosmomvpa_classifier`, :ref:`cosmomvpa_neighborhood`, and :ref:`cosmomvpa_measure` concepts.

Have a look at the :ref:`contents_demo.rst` to see how MVPA can be performed using CoSMoMVPA_.

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

