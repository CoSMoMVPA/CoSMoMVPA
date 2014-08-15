function [nbrhood,vo,fo,out2in]=cosmo_surficial_neighborhood(ds, radius, surfs, varargin)
% neighborhood definition for surface-based searchlight
%
% [nbrhood,vo,fo,out2in]=cosmo_surficial_neighborhood(ds, radius, surfs, ...)
%
% Inputs:
%    ds            fMRI-like volumetric dataset
%    radius        searchlight radius.
%                  - if radius>0, then voxels are selected around each node
%                    if the associated neighboring nodes are within a
%                    distance less than or equal to readius
%                  - if radius<0, then the nearest (-radius) voxels are
%                    selected around each node
%    surfs         cell with specification of surfaces. The following
%                  formats are valid options:
%                  * Single surface (Caret, BrainVoyager)
%                    - {fn, [start,stop]}
%                    - {fn, [start,stop], niter}
%                    - {v,f}
%                    - {v,f,[start,stop], niter}
%                    where
%                       + fn is the filename of a single surface
%                       + start and stop are distances towards and away
%                         from the center of a hemisphere. For example,
%                         if surface coordinates are in mm (which is
%                         typical), start=-3 and stop=2 means selecting
%                         voxels that are 3 mm or closer to the surface on
%                         the white-matter side, up to voxels that are 2 mm
%                         from the surface on the pial matter side
%                       + niter is the number of subsampling (mesh
%                         decimation) iterations to use for the output
%                         surface.
%                       + v are Px3 coordinates for P nodes
%                       + f are Qx3 node indices for Q faces
%                  * Twin surface (FreeSurfer)
%                    - {fn1, fn2}
%                    - {fn1, fn2,         fn_o}
%                    - {fn1, fn2,         niter}
%                    - {v1,v2,f}
%                    - {v1,v2,f,v_o,f_o}
%                    - {v1,v2,f,niter}
%                    where
%                       + fn{1,2} are filenames for pial and white
%                         surfaces
%                       + fn_o is the filename of an intermediate
%                         (node-wise average of a pial and white
%                         surface) output surface, and can be of a lower
%                         resolution than the pial and white surfaces. This
%                         can be achieved by using MapIcosahedron to
%                         generate meshes of different densities, e.g.
%                         ld=64 for the pial and white surface and ld=16
%                         for the intermediate surface. It is required that
%                         for every node in the intermediate surface there
%                         is a corresponding node (at the same spatial
%                         location) on the node-wise average of the pial
%                         and white surface.
%                       + v{1,2} are Px3 coordinates for P nodes of the
%                         pial and white surfaces
%                       + f are Qx3 node indices for Q faces on the pial
%                         and white surfaces
%                       + v_o and f_o are the nodes and vertices of an
%                         intermediate output surface
%                       + niter is the number of subsampling (mesh
%                         decimation) iterations to use for the output
%                         surface.
%    'metric',metric     distance metric along cortical surface. One of
%                        'geodesic' (default), 'dijkstra' or 'euclidian'.
%    'line_def',line_def definition of lines from inner to outer surface
%                        See surfing_nodeidxs2coords
%    'progress_step', p  Show progress every p centers (default: 100)
%    'vol_def', v        Volume definition with fields .mat (4x4 affine
%                        voxel-to-world matrix) and .dim (1x3 number of
%                        voxels in each dimension). If omittied, voldef is
%                        based on ds
%    'subsample_min_ratio', r   When niter is provided and positive, it
%                               defines the minimum ratio between surfaces
%                               of old and new faces. This should help in
%                               preventing the generation of triangles with
%                               angles close to 180 degrees (default: 0.2).
%    'center_ids', c     Center ids in output surface of the nodes for
%                        which the neighborhood should be computed. Empty
%                        means all nodes are used (default: [])
%
% Outputs:
%     nbrhood       neighborhood struct with fields
%                   .neighbors       Mx1 cell with .neighbors{k} the
%                                    indices of features (relative to ds)
%                                    in the neighborhood of node k
%                   .a.dim.labels    set to {'node_indices'}
%                   .a.dim.values    set to {center_ids} with center_ids
%                                    Mx1 ids of each neighborhood
%                   .fa.node_indices identical to center_ids
%     v_o           NVx3 coordinates for N nodes of the output surface
%     f_o           NFx3 node indices for Q faces of the output surface
%     out2in        Node mapping from output to input surface.
%
% Example:
%     % this example uses BrainVoyager Surfaces
%     anat_fn='SUB02_MPRAGE_ISO_IIHC_TAL.vmr';
%     surf_fn='SUB02_MPRAGE_ISO_IIHC_TAL_LH_RECOSM.srf';
%
%     % read dataset and surface
%     ds=cosmo_fmri_dataset(anat_fn,'mask',anat_fn);
%     fprintf('Dataset has %d samples and %d features\n',size(ds.samples));
%
%     [v,f]=surfing_read(surf_fn);
%     fprintf('Input surface has %d nodes and %d faces\n',size(v,1),size(f,1))
%
%     % define neighborhood parameters
%     radius=-100; % 100 voxels per searchlight
%     niter=10;    % 10 mesh decimation algorithms
%
%     % surface definition; voxels are selected that are 3 mm or closer to the
%     % surface on the white-matter side, up to voxels that are 1 mm from the
%     % surface on the pial matter side.
%
%     % Note: for FreeSurfer surfaces one could use
%     %       {surf_white_fn, surf_pial_fn [,niter]}
%     surfs={surf_fn,[-3 1],niter};
%     [nbrhood,vo,fo]=cosmo_surficial_neighborhood(ds,radius,surfs);
%     fprintf('Neighborhood has %d elements\n', numel(nbrhood.neighbors))
%     fprintf('Output surface has %d nodes and %d faces\n',size(vo,1),size(fo,1))
%
%     % write decimated (smaller) output surface in ASCII format
%     surfing_write(['small_surf.asc'],vo,fo);
%
%     % define a measure that counts the number of features in each searchlight
%     % (in more practical applications the measure could be, for example,
%     %  cosmo_correlation_measure or cosmo_crossvalidation_measure)
%     voxel_counter=@(x,opt) cosmo_structjoin('samples',size(x.samples,2));
%
%     % run a searchlight
%     res=cosmo_searchlight(ds,voxel_counter,'nbrhood',nbrhood);
%     fprintf('Searchlights have mean %.3f +/- %.3f features\n',...
%                     mean(res.samples), std(res.samples));
%
%
%     % store surface dataset (in AFNI/SUMA NIML format) with the number of
%     % features (voxels) for each center node of the output surface
%     s=struct();
%     s.node_indices=res.a.dim.values{1}(res.fa.node_indices);
%     s.data=res.samples';
%     surfing_write('voxcount.niml.dset',s);
%
%     % store volume dataset (in NIFTI format) with the number of times each
%     % voxel was selected by a searchlight
%     vol=ds;
%     vol.samples(:)=0;
%     for k=1:numel(nbrhood.neighbors);
%         nbrs=nbrhood.neighbors{k};
%         vol.samples(nbrs)=vol.samples(nbrs)+1;
%     end
%     cosmo_map2fmri(vol,'voxcount.nii');
%     cosmo_map2fmri(ds,'anat.nii');
%
% Notes
%  - Higher values of niter, or using a less dense mesh for fn_o or
%    (v_o, f_o) means that the output surface has fewer nodes, which will
%    decrease execution time for searchlights.
%  - This function requires the surfing toolbox, surfing.sourceforge.net or
%    github.com/nno/surfing
%
% See also: surfing, surfing_nodeidxs2coords, cosmo_searchlight
%

cosmo_check_dataset(ds,'fmri');
if ~isequal(ds.a.dim.labels,{'i','j','k'})
    error('Unsupported dimension labels, expected fMRI-like dataset');
end

cosmo_check_external('surfing');

defaults=struct();
defaults.metric='geodesic';
defaults.line_def=[10 0 1];
defaults.progress_step=100;
defaults.vol_def=[];
defaults.subsample_min_ratio=.2;
defaults.center_ids=[];
opt=cosmo_structjoin(defaults,varargin{:});

% get surfaces
[v1,v2,f,vo,fo]=parse_surfs(surfs);

one_surface=numel(v2)==2;

% define intermediate high-res surface
if one_surface
    vi=v1;
else
    vi=(v1+v2)*.5;
end

switch numel(vo)
    case 0
        % no low-res surface, so use intermediate surface as source
        vo=vi;
        fo=f;
    case 1
        % subsample the surface
        [vo,fo]=surfing_subsample_surface(vi,f,vo,opt.subsample_min_ratio);
end

% find mapping from low to high res surface
% if they are identical then low2high is the identity
out2in=surfing_maplow2hires(vo', vi');

% set volume definition
if isempty(opt.vol_def)
    vol_def=ds.a.vol;
else
    vol_def=opt.vol_def;
end

if radius<0
    % fixed number of voxels
    circle_def=[10, -radius];
else
    % fixed metric distance
    circle_def=radius;
end

% define voxel mask based on features in dataset
ds_one=cosmo_slice(ds,1);          % arbitrary sample
ds_one.samples(:)=1;               % all set to one
ds_unflat=cosmo_unflatten(ds_one); % missing features have value of zero
vol_def.mask=ds_unflat~=0;          % define mask

center_ids=opt.center_ids;
if isempty(opt.center_ids)
    center_ids=1:size(vo,1);
else
    out2in=out2in(center_ids);
end
[n2v,unused,unused_,d]=surfing_voxelselection(v1',v2',f',circle_def,...
                                         vol_def,out2in,opt.line_def,...
                                         opt.metric,opt.progress_step);

ncenters=numel(center_ids);
assert(ncenters==numel(n2v));
% determine unique center ids used
[unq_center_ids,unused,center_ids_mapping]=unique(center_ids);

% find mapping from features
nf_full=numel(vol_def.mask);
nf_mask=sum(vol_def.mask(:));
all2msk_indices=zeros(1,nf_full);
all2msk_indices(vol_def.mask)=1:nf_mask;

% store neighborhood information
nbrhood=struct();
nbrhood.a.dim.labels={'node_indices'};
nbrhood.a.dim.values={unq_center_ids};
nbrhood.fa.node_indices=center_ids_mapping(:)';
nbrhood.fa.size=d(:)';

% set neighbors while considering the masked nature of the input dataset
neighbors=cell(ncenters,1);
for k=1:ncenters
    msk_indices=all2msk_indices(double(n2v{k}));
    assert(all(msk_indices>0))
    neighbors{k}=msk_indices;
end
nbrhood.neighbors=neighbors;


function [v1,v2,f,vo,fo]=parse_surfs(surfs)
    % helper function to get surfaces
    if ~iscell(surfs)
        error('surfs argument must be a cell');
    end

    n=numel(surfs);

    % space for output
    v1=[];
    v2=[];
    f=[];
    vo=[];
    fo=[];

    for k=1:n
        s=surfs{k};
        if ischar(s)
            % filename; read the surface
            [c,f_]=surfing_read(s);
            if isempty(v1)
                v1=c;
                f=f_;
            elseif isempty(v2)
                if ~isequal(f_,f)
                    error('Topology mismatch between the two surfaces');
                end
                v2=c;
            elseif isempty(vo)
                vo=c;
                fo=f_;
            else
                error('Superfluous argument at position %d', k);
            end
        elseif isnumeric(s)
            % numeric array; coordinates or faces
            if isempty(v1)
                v1=s;
            elseif isempty(v2)
                v2=s;
            elseif isempty(f)
                f=s;
            elseif isempty(vo)
                vo=s;
            elseif isempty(fo)
                fo=s;
            else
                error('Superfluous argument at position %d', k);
            end
        else
            error('Expected surface filename or array at position %d', k);
        end
    end

    if isempty(v1) || isempty(v2) || isempty(f)
        error('Not enough arguments for two surfaces and topology');
    end

    % c2 can be vector with two elements indicating the size of the curved
    % cylinder with a circle as basis; if not, it should be a surface with
    % the same size as c1
    one_surface=numel(v2)==2;

    if ~(one_surface || isequal(size(v1),size(v2)))
        error('Size mismatch between surfaces: %dx%d != %dx%d',...
                    size(v1), size(v2));
    end

    surfing_check_surface(v1,f);
    if ~one_surface
        surfing_check_surface(v2,f);
    end

    if isempty(fo)
        if numel(vo)>1
            % if not a scaler (niter) then throw an error
            error('Topology missing for output surface');
        end
    else
        surfing_check_surface(vo,fo);
    end


