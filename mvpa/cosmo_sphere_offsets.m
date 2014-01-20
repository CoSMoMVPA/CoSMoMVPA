function [offsets,distances]=cosmo_sphere_offsets(radius)
% computes sub index offsets for voxels in a sphere
%
% [offsets,distances]=cosmo_sphere_offsets(radius)
%
% Input:
%  radius      radius of the sphere (in voxel units)
% 
% Output
%  offsets     Px3 sub indices relative to the origin (0,0,0).
%              offsets(p,:)=[i, j, k] means that the euclidian distance 
%              between points at (i,j,k) and the origin is less than or 
%              or equal to radius
%  distances   Px1 distances from the origin (in voxel units)
%
% Notes:
%  - offsets and distances are sorted by distance
%  
% Example:
%  - % compute offsets for voxels that share a side or edge, but not those
%    % that only share a corner
%    >> [o, d]=cosmo_sphere_offsets(1.5);
%    >> o'
%    [ 0 -1  0  0 0 0 1 -1 -1 -1 -1  0  0  0 0  1  1 1 1;
%      0  0 -1  0 0 1 0 -1  0  0  1 -1 -1  1 1 -1  0 0 1;
%      0  0  0 -1 1 0 0  0 -1  1  0 -1  1 -1 1  0 -1 1 0 ]
%    >> d'
%    [ 0 1 1 1 1 1 1 1.4142 1.4142 1.4142 1.4142 1.4142 1.4142
%      1.4142 1.4142 1.4142 1.4142 1.4142 1.4142 ]
%
% See also sub2ind, ind2sub, cosmo_spherical_voxel_selection
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
    
    % Consider the candidates in all three spatial dimensions using
    % nested for loops and an if statement.
    % For each position:
    % - see if it is at most at distance 'radius' from the origin
    % - if that is the case, increase row_pos and store the position in
    %   'offsets'
    %
    % >@@>
    for x=single_dimension_candidates
        for y=single_dimension_candidates
            for z=single_dimension_candidates
                if x^2+y^2+z^2<=radius^2
                    row_pos=row_pos+1;
                    offsets(row_pos,:)=[x y z];
                end
            end
        end
    end
    % <@@<
    
    % cut off empty values at the end
    offsets=offsets(1:row_pos,:);
    
    % compute distances
    distances=sqrt(sum(offsets.^2,2));
    
    % sort distances and apply to offsets
    [distances,idxs]=sort(distances);
    offsets=offsets(idxs,:);
    
                