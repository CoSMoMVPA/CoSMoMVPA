.. solution_4

For-loop for N-fold partioner
=============================

.. code-block:: matlab

   % >>
   for k=1:nchunks
       test_msk=unq(k)==chunks;
        train_indices{k}=find(~test_msk)';
        test_indices{k}=find(test_msk)';
   end
   % <<

