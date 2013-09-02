function ds = cosmo_fmri_dataset(filename, varargin)
% load an fmri dataset to facilitate MVPA analyses. Fashioned after
% the logic and semantics of PyMVPA. 
%
% ds = cosmo_fmri_dataset(filename, [,'mask',mask],...
%                                   ['targets',targets],...
%                                   ['chunks',chunks])
% 
% Inputs:
%   filename     filename for dataset. Currently supports NIFTI and ANALYZE
%   mask         filename for volume mask
%   targets      Nx1 array of numeric labels to be used as sample attributes
%   chunks       Nx1 array of numeric labels to be used as feature attributes
%
% Returns:
%   ds           dataset struct with the following fields:
%     .samples   NxM matrix containing the data loaded from filename, for
%                N samples (observations, volumes) and M features (spatial
%                locations, voxels).
%                If the original nifti file contained data with X,Y,Z,T
%                dimensions, and no mask was applied, then 'data' will have
%                dimensions N x M, where N = T, and M = X*Y*Z. If a mask was
%                applied then M = the number of non-zero voxels in the mask
%                input dataset.
%     .a         struct intended to contain dataset-relevent data.
%     .a.hdr_{F} header information for this dataset, required to map the data
%                back to a volumetric data file. Currently {F} can be 
%                'nii'.
%     .sa        struct for holding sample attributes (e.g.,sa.targets,sa.chunks) 
%     .fa        struct for holding sample attributes 
%     .fa.voxel_indices   M * 3 indices of voxels (in volume space). 
%
% Dependencies:
% - for NIFTI files, it requires the following toolbox:
%   http://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
%   (note that his toolbox is included in CoSMoMVPA in /externals)
%
% ACC, NNO Aug, Sep 2013

% Input parsing stuff
parser = inputParser;
addRequired(parser,'filename');
addOptional(parser,'mask',[]); 
addOptional(parser,'targets',[]);
addOptional(parser,'chunks',[]);
parse(parser,filename,varargin{:})
p = parser.Results;

% define which formats are supports
img_formats=struct();
img_formats.nii.exts={'.nii','.nii.gz','.hdr','.img'};
img_formats.nii.reader=@read_nii; % this is a wrapper defined below

% read the image (using a helper function defined below
[data,hdr,img_format]=read_img(p.filename, img_formats);


dims = size(data);
if sum(numel(dims)==[3 4])~=1, 
    error('Need 3 or 4 dimensions'); 
end

nx = dims(1); ny = dims(2); nz = dims(3); 

% is the volume 4D?
is_4d=numel(size(data))==4;
if is_4d
    nt = dims(4);
else
    nt=1;
end

% if a mask was supplied, load it
if ~isempty(p.mask)
    if ischar(p.mask)
        m = read_img(p.mask, img_formats);
    else
        m = p.mask;
    end

    mdim = size(m);

    % mask has to be 3D or 4D
    switch numel(mdim)
        case 3
        case 4
            m=m(:,:,:,1);
            warning('Found mask with %d volumes - using first', mdim(4));
        otherwise
            error('illegal mask');
    end

    % sanity check to ensure the mask is properly shaped
    if ~isequal(dims(1:3), mdim(1:3))
        error('mask size is different from data size');
    end

    mask_indices = find(m);
else
    mask_indices = [1:(nx*ny*nz)]'; % use all voxel indices
end

% compute the voxel indices
[ix, iy, iz] = ind2sub([nx,ny,nz], mask_indices);
ds.fa.voxel_indices=[ix iy iz]';

% store the volume data
nfeatures=numel(mask_indices);
ds.samples = zeros(nt, nfeatures);

for v=1:nt
    if is_4d
        vol = data(:,:,:,v);
    else
        vol = data(:,:,:);
    end
    ds.samples(v,:)=vol(mask_indices); % apply the mask
end

header_name=['hdr_' img_format];
ds.a.(header_name) = hdr; % store header

ds=set_sa_vec(ds,p,'targets');
ds=set_sa_vec(ds,p,'chunks');


function ds=set_sa_vec(ds,p,fieldname)
% helper: sets a sample attribute as a vector
% throws an error if it has the from size
nsamples=size(ds.samples,1);
v=p.(fieldname);
n=numel(v);
if not (n==0 || n==nsamples)
    error('size mismatch for %s: expected %d values, found %d', ...
                    fieldname, nsamples, n);
end
ds.sa.(fieldname)=v(:);

function img_format=find_img_format(filename, img_formats)
% helper: find image format of filename fn
fns=fieldnames(img_formats);
n=numel(fns);
for k=1:n
    fn=fns{k};
    exts=img_formats.(fn).exts;
    m=numel(exts);
    for j=1:m
        ext=exts{j};
        d=numel(ext)-1;
        if numel(filename) <= d 
            continue % filename is too short
        end
        if strcmpi(filename(end+(-d:0)), ext)
            img_format=fn;
            return
        end
    end
end
error('Could not find image format for %s', fn)


function [data,hdr,img_format]=read_img(fn, img_formats)
% helper: returns data (3D or 4D), header, and a string indicating the
% image format. It matches the filename extension with what is stored
% in img_formats

img_format=find_img_format(fn, img_formats);

reader=img_formats.(img_format).reader;

[data,hdr]=reader(fn);

function [data,hdr]=read_nii(fn)
hdr=load_nii(fn);  
data=hdr.img;
hdr=rmfield(hdr,'img');


