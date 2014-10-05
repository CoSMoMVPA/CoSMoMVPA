.. _tips:


Tips and tricks
===============

Here is a short list of tips and tricks that may make life easier when using CoSMoMVPA_.

- Use :ref:`cosmo_disp` to show the contents of a dataset structure (or any other data structure)

- Use ``help cosmo_function`` to view the help contents of a function. Most functions have an ``example`` section which shows how the function can be used.

- Use :ref:`cosmo_check_dataset` when manually changing contents of a dataset structure. It will catch basic errors in dataset

- Use :ref:`cosmo_check_partitions` when manually creating partitions.

- When slicing datasets, often :ref:`cosmo_match` can be used to get logical masks that match a (array of) numbers of strings.
- For feature selection in MEEG datasets (in particular, selection over time), consider :ref:`cosmo_dim_match` and :ref:`cosmo_dim_prune`.

.. include:: links.txt



