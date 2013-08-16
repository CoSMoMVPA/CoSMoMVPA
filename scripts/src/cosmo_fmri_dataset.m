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


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Input parsing stuff
    parser = inputParser;
    addRequired(parser,'filename');
    addOptional(parser,'mask',[]); 
    addOptional(parser,'targets',[]);
    addOptional(parser,'chunks',[]);
    parse(parser,filename,varargin{:})
    p = parser.Results;
    
    % End input parsing stuff
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    extensions={'.nii','.nii.gz'};
    fn=find_file(p.filename, extensions); 
    ni = load_nii(fn);

    dims = size(ni.img);
    if numel(dims)>4, 
        error('Found more than 4 dimensions'); 
    end
    x = dims(1); y = dims(2); z = dims(3); t = dims(4);
    
    % if a mask was supplied, load it
    if ~isempty(p.mask)
        if ischar(p.mask)
            m = load_nii(p.mask);
            m = m.img;
        else
            m = p.mask;
        end
        mdim = size(m);

        switch length(mdim)
            case 3
            case 4
                m=m(:,:,:,1);
            otherwise
                error('illegal mask');
        end
        
        if ~isequal(dims(1:3), mdim(1:3))
            error('mask size is different from data size');
        end
        
        ds.a.mapper = find(m);
    else
        ds.a.mapper = [1:(x*y*z)]; 
    end
    
    % compute the voxel indices
    [ix, iy, iz] = ind2sub([x,y,z], ds.a.mapper);
    ds.fa.voxel_indices=[ix iy iz]';
    
    % store the volume data
    nfeatures=numel(ds.a.mapper);
    ds.samples = zeros(t, nfeatures);
    
    for v=1:t
        vol = ni.img(:,:,:,v);
        ds.samples(v,:)=vol(ds.a.mapper);
    end
    
    ni=rmfield(ni,'img'); % remove data from header
    ds.a.imghdr = ni; % store header
    
    ds=set_sa_vec(ds,p,'targets');
    ds=set_sa_vec(ds,p,'chunks');
end

function ds=set_sa_vec(ds,p,fieldname)

    nsamples=size(ds.samples,1);
    v=p.(fieldname);
    n=numel(v);
    if not (n==0 || n==nsamples)
        error('size mismatch for %s: expected %d values, found %d', fieldname, nsamples, n);
    end
    ds.sa.(fieldname)=v(:);
end
    

function fn=find_file(fn, exts)

if exist(fn,'file')
    return;
end
nf=numel(fn);
n=numel(exts);
for k=1:n
    ext=exts{k};
    ne=numel(ext);
    d=nf-ne+1;
    if isempty(findstr(fn,ext)) || ~strcmp(fn(d:end), ext)
        continue
    end
    for j=1:n
        fne=[fn(1:(d-1)) exts{j}];
        if exist(fne,'file')
            fn=fne;
            disp('found')
            return
        end
    end
end
end
    


