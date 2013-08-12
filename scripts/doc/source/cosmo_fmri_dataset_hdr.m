function ds = cosmo_fmri_dataset(filename, varargin)
% FMRI_DATASET load an fmri dataset to facilitate MVPA analyses. Fashioned after
%               the logic and semantics of PyMVPA. 
%
%   DS = COSMO_FMRI_DATASET(nifti_filename) 
%   
%   returns struct (ds) that has the data 
%   in 2-D matrix format. N-rows hold N-volumes (e.g., samples, observations, timepoints)
%   and M columns for M features (e.g., voxels).
% 
% OPTIONAL ARGUMENTS:
%   'mask'  -- nifti filename for volume mask
%   'targets' -- a 1 x N array of numeric labels to be used as sample attributes
%   'chunks' -- a 1 x M array of numeric labels to be used as feature attributes
%
% RETURNS: DATASET 'DS':
%   ds is a struct with the following fields:
%       'samples' -- 2-D matrix containing the data loaded from nifti_filename
%                   If the original nifti file contained data with X,Y,Z,T
%                   dimensions, and no mask was applied, then 'data' will have
%                   dimensions N x M, where N = T, and M = X*Y*Z. If a mask was
%                   applied then M = the number of non-zero voxels in the mask
%                   input dataset.
%       'a' -- Dataset attributes. A struct containing Dataset relevent data.
%          
%       'a.imghdr' -- A struct that contains all of the information in the nifti
%                   header. This struct is nearly the same as the output from
%                   load_nii, with the exception that hdr.img is not kept (to
%                   save memory).
%                   load_nii comes from:
%                 http://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
%       'a.mapper' -- An array of indices into the original flattened volume
%                   before masking, for use in mapping data back into original space.
%       'sa' -- A struct for holding Sample Attributes (e.g.,sa.targets,sa.chunks) 
%       'fa'  -- Feature attributes 
%       'fa.voxel_indices' -- M * 3 indices of voxels
%
%