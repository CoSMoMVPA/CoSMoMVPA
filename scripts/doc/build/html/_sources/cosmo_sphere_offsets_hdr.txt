.. cosmo_sphere_offsets_hdr

cosmo sphere offsets hdr
------------------------
.. code-block:: matlab

    function offsets=cosmo_sphere_offsets(radius)
    % computes sub index offsets for voxels in a sphere
    %
    % offsets=cosmo_sphere_offsets(radius)
    %
    % Input
    %  - radius    radius of the sphere (in voxel units)
    % 
    % Output
    %  - offsets   Px3 sub indices relative to the origin (0,0,0).
    %              offsets(p,:)=[i, j, k] means that the euclidian distance 
    %              between points at (i,j,k) and the origin is less than or 
    %              or equal to radius
    %
    % Example
    % cosmo_sphere_offsets(1)
    % >   [-1     0     0
    % >     0    -1     0
    % >     0     0    -1
    % >     0     0     0
    % >     0     0     1
    % >     0     1     0
    % >     1     0     0]
    %
    % See also sub2ind, ind2sub
    %
    % NNO Aug 2013