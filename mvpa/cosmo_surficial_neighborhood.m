function [nbrhood,vo,fo,out2in]=cosmo_surficial_neighborhood(ds, surfs, varargin)
% neighborhood definition for surface-based searchlight
%
% [nbrhood,vo,fo,out2in]=cosmo_surficial_neighborhood(ds, surfs, ...)
%
% Inputs:
%    ds            fMRI-like volumetric or surface-based dataset
%    surfs         cell with specification of surfaces. The following
%                  formats are valid options:
%                  # Volumetric datasets:
%                    * Single surface (Caret, BrainVoyager)
%                      - {fn, [start,stop]}
%                      - {fn, [start,stop], niter}
%                      - {v,f,[start,stop], niter}
%                      where
%                         + fn is the filename of a single surface
%                         + start and stop are distances towards and away
%                           from the center of a hemisphere. For example,
%                           if surface coordinates are in mm (which is
%                           typical), start=-3 and stop=2 means selecting
%                           voxels that are 3 mm or closer to the surface
%                           on the white-matter side, up to voxels that are
%                           2 mm from the surface on the pial matter side
%                         + niter is the number of subsampling (mesh
%                           decimation) iterations to use for the output
%                           surface.
%                         + v are Px3 coordinates for P nodes
%                         + f are Qx3 node indices for Q faces
%                    * Twin surface (FreeSurfer)
%                      - {fn1, fn2}
%                      - {fn1, fn2,         fn_o}
%                      - {fn1, fn2,         niter}
%                      - {v1,v2,f}
%                      - {v1,v2,f,v_o,f_o}
%                      - {v1,v2,f,niter}
%                      where
%                         + fn{1,2} are filenames for pial and white
%                           surfaces
%                         + fn_o is the filename of an intermediate
%                           (node-wise average of a pial and white
%                           surface) output surface, and can be of a lower
%                           resolution than the pial and white surfaces.
%                           This  can be achieved by using MapIcosahedron
%                           to generate meshes of different densities, e.g.
%                           ld=64 for the pial and white surface and ld=16
%                           for the intermediate surface. It is required
%                           that for every node in the intermediate surface
%                           there is a corresponding node (at the same
%                           spatial location) on the node-wise average of
%                           the pial and white surface.
%                         + v{1,2} are Px3 coordinates for P nodes of the
%                           pial and white surfaces
%                         + f are Qx3 node indices for Q faces on the pial
%                           and white surfaces
%                         + v_o and f_o are the nodes and vertices of an
%                           intermediate output surface. It is required
%                           that the vertices in v_o are a subset of the
%                           pair-wise averages of vertices in v1 and v2. A
%                           typical use case is using standard topologies
%                           from AFNI's MapIcosahedron, where the v1 and v2
%                           are high-res with X linear divisions, v_o is
%                           low-res with Y linear divisions, and Y<X and X
%                           is an integer multiple of Y.
%                         + niter is the number of subsampling (mesh
%                           decimation) iterations to use for the output
%                           surface.
%                  # Surface-based datasets:
%                    - {fn}
%                    - {fn, niter}
%                    - {v, f, niter}
%    'radius', r         } select neighbors either within radius r, grow
%    'count', c          } the radius to get neighbors are c locations,
%    'direct', true      } or get direct neighbors only (nodes who share an
%                        } edge)
%                        } These three options are mutually exclusive
%    'metric',metric     distance metric along cortical surface. One of
%                        'geodesic' (default), 'dijkstra' or 'euclidean'.
%    'line_def',line_def definition of lines from inner to outer surface
%                        See surfing_nodeidxs2coords
%    'progress', p       Show progress every p centers (default: 100)
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
%                   .a.fdim.labels   set to {'node_indices'}
%                   .a.fdim.values   set to {center_ids} with center_ids
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
%     count=100; % 100 voxels per searchlight
%     niter=10;    % 10 mesh decimation algorithms
%
%     % surface definition; voxels are selected that are 3 mm or closer to the
%     % surface on the white-matter side, up to voxels that are 1 mm from the
%     % surface on the pial matter side.
%
%     % Note: for FreeSurfer surfaces one could use
%     %       {surf_white_fn, surf_pial_fn [,niter]}
%     surfs={surf_fn,[-3 1],niter};
%     [nbrhood,vo,fo]=cosmo_surficial_neighborhood(ds,surfs,'radius',radius);
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
%     s.node_indices=res.a.fdim.values{1}(res.fa.node_indices);
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
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

cosmo_check_external('surfing');

check_input(surfs, varargin{:});

defaults=struct();
defaults.metric='geodesic';
defaults.line_def=[10 0 1];
defaults.progress=100;
defaults.vol_def=[];
defaults.subsample_min_ratio=.2;
defaults.center_ids=[];
opt=cosmo_structjoin(defaults,varargin{:});

ds_type=get_ds_type(ds);

if strcmp(opt.metric,'geodesic') && ~isfield(opt,'direct')
    cosmo_check_external('fast_marching');
end

% get surfaces
[v1,v2,f,vo,fo]=parse_surfs(surfs, ds_type);
ds_is_surface=strcmp(ds_type, 'surface');

one_surface=numel(v2)==2 || (ds_is_surface && isempty(v2));

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
        [vo,fo]=surfing_subsample_surface(vi,f,vo,...
                                opt.subsample_min_ratio, opt.progress);
end

% find mapping from low to high res surface
% if they are identical then low2high is the identity
out2in=surfing_maplow2hires(vo', vi');



% set center ids
center_ids=opt.center_ids(:)'; % ensure row vector
if isempty(opt.center_ids)
    center_ids=1:size(vo,1);
else
    out2in=out2in(center_ids);
end

% either surface or volumetric input dataset
ds_is_surface=cosmo_check_dataset(ds,'surface',false);
ds_is_volume=cosmo_check_dataset(ds,'fmri',false);

if sum([ds_is_surface, ds_is_volume])~=1
    error('Unsupported dataset: expected surface or fmri dataset');
end

if ds_is_surface
    % todo: use out2in to allow for subset of node indices as center
    %       (the current implementation computes neighborhoods for all
    %       nodes)
    if ~isequal(center_ids,1:size(vo,1))
        error('Unsupported center_ids option');
    end

    if ~isequal(out2in',1:numel(out2in))
        %error('Unsupported other output surface than input surface');
    end

    nbrhood=surface_to_surface_neighborhood(ds,vi,f,opt);


elseif ds_is_volume
    % get circle definition
    circle_def=get_circle_def(opt);

    % set volume definition
    if isempty(opt.vol_def)
        vol_def=ds.a.vol;
    else
        vol_def=opt.vol_def;
    end



    % define voxel mask based on features in dataset
    ds_one=cosmo_slice(ds,1);          % arbitrary sample
    ds_one.samples(:)=1;               % all set to one
    ds_unflat=cosmo_unflatten(ds_one); % missing features have value of zero
    vol_def.mask=ds_unflat~=0;          % define mask


    n2v=surfing_voxelselection(v1',v2',f',circle_def,vol_def,...
                                             out2in,opt.line_def,...
                                             opt.metric,0+opt.progress);

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
    nbrhood.a.fdim.labels={'node_indices'};
    nbrhood.a.fdim.values={unq_center_ids};
    nbrhood.fa.node_indices=center_ids_mapping(:)';

    % set neighbors while considering the masked nature of the input dataset
    neighbors=cell(ncenters,1);
    for k=1:ncenters
        msk_indices=all2msk_indices(double(n2v{k}));
        assert(all(msk_indices>0));
        neighbors{k}=msk_indices;
    end
    nbrhood.neighbors=neighbors;

else
    assert(false,'this should never happen');
end

% compatibility wrapper for the surfing toolbox
nbrhood=ensure_neighbors_row_vectors(nbrhood);

origin=struct();
origin.a=ds.a;
origin.fa=ds.fa;
nbrhood.origin=origin;


cosmo_check_neighborhood(nbrhood,ds);


function nbrhood=surface_to_surface_neighborhood(ds,vertices,faces,opt)
    circle_def=get_circle_def(opt);
    dim_label='node_indices';

    [two,fdim_index,attr_name,dim_name]=cosmo_dim_find(ds,...
                                        dim_label,true);

    fdim_nodes=ds.a.(dim_name).values{fdim_index};
    fa_indices=ds.(attr_name).(dim_label);

    if ~isequal(sort(fdim_nodes), unique(fdim_nodes))
        error('values in .a.%s.values{%d} are not all unique',...
                    dim_name, fdim_index);
    end



    % - unq_nodes contains the node index associated with each unique
    %   node_indices feature in the dataset
    [fa_idxs,unq_fa_indices]=cosmo_index_unique(fa_indices');
    unq_nodes=fdim_nodes(unq_fa_indices);

    nvertices=size(vertices,1);

    too_large_index=find(unq_nodes>nvertices,1);
    if any(too_large_index)
        error(['surface has %d vertices, but maximum .fa.%s '...
                    'is %d'],...
                    nvertices,dim_label,fa_node_ids(too_large_index));
    end

    ignore_vertices_msk=true(nvertices,1);
    ignore_vertices_msk(unq_nodes)=false;

    vertices(ignore_vertices_msk,:)=NaN;

    % set mapping from nodes to feature ids
    ncenters=numel(unq_fa_indices);
    node2feature_ids=cell(1,nvertices);
    for k=1:ncenters
        node=unq_nodes(k);
        if ignore_vertices_msk(node)
            feature_ids=cell(1,0);
        else
            feature_ids=fa_idxs{k};
        end
        node2feature_ids{node}=feature_ids;
    end


    % run node selection
    [n2ns,radii]=surfing_nodeselection(vertices',faces',circle_def,...
                                        opt.metric,opt.progress);

    % set output
    nbrhood=struct();
    nbrhood.a.fdim.labels={'node_indices'};
    nbrhood.a.fdim.values={fdim_nodes};


    nbrhood.neighbors=cell(ncenters,1);
    nbrhood.fa.radius=zeros(1,ncenters);
    nbrhood.fa.node_indices=zeros(1,ncenters);

    for k=1:ncenters
        center_node=unq_nodes(k);
        nbrhood.fa.node_indices(k)=unq_fa_indices(k);
        nbrhood.fa.radius(k)=radii(center_node);

        if ignore_vertices_msk(center_node)
            around_feature_ids=zeros(1,0);
        else
            around_nodes=n2ns{center_node};
            around_feature_ids=cat(1,node2feature_ids{around_nodes});
        end

        nbrhood.neighbors{k}=around_feature_ids(:)';
    end



function nbrhood=ensure_neighbors_row_vectors(nbrhood)
    % compatibility wrapper for the surfing toolbox
    for k=1:numel(nbrhood.neighbors)
        if ~isrow(nbrhood.neighbors{k})
            nbrhood.neighbors{k}=nbrhood.neighbors{k}';
        end
    end

function [v1,v2,f,vo,fo]=parse_surfs(surfs, ds_type)
    % helper function to get surfaces

    ds_is_surface=strcmp(ds_type,'surface');

    [v1,v2,f,vo,fo]=parse_surfs_arguments(ds_is_surface, surfs);

    if numel(v2)~=2 && (numel(f)==2 || isempty(f))
        % swap position
        temp=f;
        f=v2;
        v2=temp;
    end

    check_surf_arguments(ds_is_surface,v1,v2,f,vo,fo);


function check_surf_arguments(ds_is_surface,v1,v2,f,vo,fo)


    if isempty(v1) || (isempty(v2) && ~ds_is_surface) || isempty(f)
        error('Not enough arguments for surfaces and topology');
    end

    % c2 can be vector with two elements indicating the size of the curved
    % cylinder with a circle as basis; if not, it should be a surface with
    % the same size as c1
    one_surface=numel(v2)==2;

    if ~(one_surface || ds_is_surface || isequal(size(v1),size(v2)))
        error('Size mismatch between surfaces: %dx%d != %dx%d',...
                    size(v1), size(v2));
    end

    surfing_check_surface(v1,f);
    if ~(one_surface || ds_is_surface)
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



function [v1,v2,f,vo,fo]=parse_surfs_arguments(ds_is_surface,surfs)
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
            elseif isempty(v2) && ~ds_is_surface
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


function ds_type=get_ds_type(ds)

    supported_ds_types={'surface','fmri'};
    n=numel(supported_ds_types);

    for k=1:n
        supported_ds_type=supported_ds_types{k};
        if cosmo_check_dataset(ds,supported_ds_type,false)
            ds_type=supported_ds_type;
            return
        end
    end

    % maybe it is not a dataset at all, check this possibility
    cosmo_check_dataset(ds);

    % it is a valid dataset but not fmri or surface;
    % try to give an appropriate error message
    for k=1:n
        supported_ds_type=supported_ds_types{k};
        if is_ds_type_like(ds, supported_ds_type)
            % let it throw an error
            cosmo_check_dataset(ds,supported_ds_type);
        end
    end

    error('Unknown dataset type, supported are: %s.', ...
                    cosmo_strjoin(supported_ds_types,', '));


function tf=is_ds_type_like(ds, type)
    % helper function that uses heuristics to find type of dataset
    tf=false;

    switch type
        case 'surface'
            if cosmo_isfield(ds,'fa.node_indices')
                tf=true;
                return;
            end

            if cosmo_isfield(ds,'a.fdim.values') && ...
                        isequal({'node_indices'},ds.a.fdim.values)
                tf=true;
                return;
            end

        case 'fmri'
            if any(cosmo_isfield(ds,{'fa.i','fa.j','fa.k'}))
                tf=true;
                return;
            end

            if cosmo_isfield(ds,'a.fdim.values') && ...
                        any(cosmo_match({'i','j','k'},ds.a.fdim.values))
                tf=true;
                return
            end

        otherwise
            error('unsupported type %s', type);
    end

function check_input(surfs, varargin)
    % give deprecation notice
    if isnumeric(surfs)
        error(['Second argument must be a cell with a surface '...
                'definition (as of Jan 2015, the syntax for this '...
                'function has changed)']);
    end


function circle_def=get_circle_def(opt)
    metric2circle_def_func=struct();
    metric2circle_def_func.radius=@(x)x;
    metric2circle_def_func.count=@(x)[0 x]; % fixed initial radius
    metric2circle_def_func.direct=@get_direct_circle_def;

    % options are mutually exclusive
    metrics=fieldnames(metric2circle_def_func);
    metric_msk=cosmo_isfield(opt,metrics);
    if sum(metric_msk)~=1
        error('Use one of these arguments to define neighbors: %s',...
                cosmo_strjoin(metrics, ', '));
    end

    metric=metrics{metric_msk};
    func=metric2circle_def_func.(metric);
    param=opt.(metric);
    if ~isscalar(param) || param<0
        error('value for ''%s'' must be a scalar not less than zero',...
                metric);
    end
    circle_def=func(opt.(metric));

function circle_def=get_direct_circle_def(radius)
    % false or 0 give a zero radius, otherwise NaN
    if isnan(radius) || radius
        circle_def=NaN;
    else
        circle_def=[5 1];
    end









