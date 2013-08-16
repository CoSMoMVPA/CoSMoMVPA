.. cosmo_sphere_offsets_skl

cosmo sphere offsets skl
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
    
    % how big a box should be to contain all voxels with the given radius
    side=ceil(radius)*2+1;
    
    % make an array that is sufficienly large (actually too big)
    offsets=zeros(side^3,3);
    
    % keep track of where we store indices in offsets:
    % for every location within the sphere (in the code below), 
    % add one to row_pos and then store the locations
    row_pos=0;
    
    % the grid positions (relative to the origin) to consider
    single_dimension_candidates=floor(-radius):ceil(radius);
    
    % consider the candidates in all three spatial dimensions using
    % nested for loops and an if statement
    %%%% >>> YOUR CODE HERE <<< %%%%
    
    % cut off empty values at the end
    offsets=offsets(1:row_pos,:);
                