function ds_plumb=cosmo_fmri_deoblique(ds)
% de-oblique a dataset
%
% Input:
%     ds                fmri dataset struct
%
% Output:
%
% Example:
%     % start with a simple dataset
%     x=cosmo_synthetic_dataset('size','huge','ntargets',1,'nchunks',1);
%     % make dataset oblique (manually)
%     x.a.vol.mat(1,1)=.8;
%     x.a.vol.mat(2,1)=.6;
%     y=cosmo_fmri_deoblique(x);
%     cosmo_disp(x.a.vol)
%     > .mat
%     >   [ 0.8         0         0        -3
%     >     0.6         2         0        -3
%     >       0         0         2        -3
%     >       0         0         0         1 ]
%     > .dim
%     >   [ 20        17        19 ]
%     > .xform
%     >   'scanner_anat'
%     cosmo_disp(y.a.vol)
%     > .mat
%     >   [ 1         0         0      -3.2
%     >     0         2         0      -2.4
%     >     0         0         2        -3
%     >     0         0         0         1 ]
%     > .dim
%     >   [ 20        17        19 ]
%     > .xform
%     >   'scanner_anat'
%     %
%     % other attributes are unchanged:
%     assert(isequal({x.samples x.fa x.sa x.a.fdim},...
%                    {y.samples y.fa y.sa y.a.fdim}));
%     %
%     % a plump dataset does not change after de-obliqueing
%     z=cosmo_fmri_deoblique(y);
%     isequal(y,z)
%     > true
%
% Notes:
%   - Using this function changes the location of the voxels in
%     world-space, that is world coordinates (x, y, z).
%   - This function is intended for AFNI and BrainVoyager, as these
%     programs prefer 'plump' (non-oblique) volumes.
%   - When using this function, it is recommended to inspect the result
%     visually.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

% get canonical orthogonal matrix
[unused,rot_ortho]=cosmo_fmri_orientation(ds);
mat=ds.a.vol.mat;


% convert base1 -> base0
mat(1:3,4)=mat(1:3,4)+mat(1:3,1:3)*[1 1 1]';

% use pixel dimension to set non-zero elements
mat_ortho=mat;
pixdim=sqrt(sum(mat(1:3,1:3).^2,1));
mat_ortho(1:3,1:3)=bsxfun(@times,rot_ortho(1:3,1:3),pixdim);

% convert base0 -> base1
mat_ortho(1:3,4)=mat_ortho(1:3,1:3)*-[1 1 1]'+mat_ortho(1:3,4);

% ensure single element in rotation part
assert(all(sum(mat_ortho(:,1:3)~=0,1)==1));
assert(all(sum(mat_ortho(1:3,1:3)~=0,2)==1));

ds_plumb=ds;
ds_plumb.a.vol.mat=mat_ortho;


