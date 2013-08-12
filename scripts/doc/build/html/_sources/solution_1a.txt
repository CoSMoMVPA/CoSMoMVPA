.. solution_1a

Dataset Basics
==============


.. code-block:: matlab
    
    % Load the dataset with VT mask
    ds = fmri_dataset('../data/s01/glm_T_stats_perrun.nii.gz', ...
                        'mask', '../data/s01/vt_mask.nii.gz')
    
    % set the targets and the chunks
    ds.targets = repmat([1:6],1,10);
    chunks = []; for i=1:10 chunks = [chunks repmat(i,1,6)]; end
    ds.chunks = chunks;

    % Add labels as sample attributes
    labels = {'monkey','lemur','mallard','warbler','ladybug','lunamoth'};
    ds.sa.labels = repmat(labels,1,10)
    
