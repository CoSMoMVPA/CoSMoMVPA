.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`ex_meeg_time_generalization`:

MEEG time generalization
========================

Requirements
++++++++++++
This exercise requires a separate dataset named `meg-obj6`; see :ref:`download <download>` section.
It also requires a working installation of FieldTrip_.

Reading material
++++++++++++++++

- :cite:`KiD14`: Description of the time generalization method.
- :cite:`KOP16`: Paper using the time generalization method.



The time generalization method
++++++++++++++++++++++++++++++

Load the `meg-obj6` data. Assign targets and chunks, then select only posterior gradiometer sensors in the time interval between 0 and 300 ms relative to stimulus onset. Then reduce the number of chunks to two (using :ref:`cosmo_chunkize`) to get a train and test set.
Use :ref:`cosmo_dim_generalization_measure` for the ``time`` dimension, together with :ref:`cosmo_classify_lda` and :ref:`cosmo_crossvalidation_measure` to train for all time points in the 0-300 ms interval, and for each time point, test the classifier for each time point in the same interval. Display the resulting time-by-time classification accuracy matrix using ``imagesc``

Template: :ref:`run_meeg_time_generalization_skl`

Check your answers here: :ref:`run_meeg_time_generalization` / :pb:`meeg_time_generalization`

.. include:: links.txt




