.. run_setting_sample_attr_skl

run setting sample attr skl
===========================
.. code-block:: matlab

    %% Dataset Basics
    % Set the targets and the chunks
    %
    % There are 10 runs with 6 volumes per run. The runs are vertically stacked one
    % above the other. The six volumes in each run correspond to the stimuli:
    % 'monkey','lemur','mallard','warbler','ladybug','lunamoth', in that order. Add
    % numeric targets labels (samples atribute) such that 1 corresponds to 'monkey',
    % 2 corresponds to 'lemur', etc. Then add numeric chunks (another samples
    % attribute) so that 1 corresponds to run1, 2 corresponds to run2, etc.
    
    %% Load the dataset
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    %% Show the results
    
    % print the dataset
    ds
    
    % print the sample attributes
    ds.sa
    
    % print the chunks
    ds.sa.chunks
    
    % print the targets
    ds.sa.targets
    
    
    
    