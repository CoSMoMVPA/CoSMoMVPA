function nbrhood=cosmo_cluster_neighborhood(ds,varargin)
% define neighborhood suitable for cluster-based analysis
%
% nbrhood=cosmo_cluster_neighborhood(ds,...)
%
% Inputs:
%     ds            dataset struct
%     'fmri',nn     Optional connectivity for voxels, if ds is an
%                   fmri dataset. Use nn=1, 2 or 3 to let voxels be
%                   neighbors if they share at least a a side, edge
%                   or vertex (respectively).
%                   Default: 3
%     'chan',c      Optional connectivity for channels, if ds is an MEEG
%                   dataset with channels. c=true makes channels neighbors
%                   if their Delaunay triangulation (as computed by
%                   cosmo_meeg_chan_neighors) has them share an edge.
%                   c=false means that a channel is only neighbor of
%                   itself.
%                   Default: true
%     'surface',s   Optional connectivity for nodes, if ds is a
%                   surface-based dataset. s=true makes channels neighbors
%                   if they share an edge on the surface.
%                   c=false means that a channel is only neighbor of itself
%                   Default: true
%     'vertices',v  } vertices (Px3) and faces (Qx3) of the surface;
%     'faces',f     } only required for a surface-based dataset
%     k,t           Any other feature dimension and its connectivity, e.g.
%                   k can be 'chan' or 'freq'. t indicates whether
%                   neighboring points (in time, freq, ...) are neighbors.
%                   Default: true (for any dimension not mentioned above)
%
%  Output:
%     nbrhood       Neighborhood struct
%       .neighbors  .neighbors{k}==idxs means that feature k in ds has
%                   neighbors with feature indices idxs
%       .fa         identical to ds.fa, except that a field .sizes
%                   is added indicating the size of each feature
%                   - for surfaces, this is the area of each node
%                   - in all other cases, it is set to a vector of ones.
%       .a          identical to ds.a
%
%  Examples:
%     % get neighbors in very tiny synthetic fmri dataset (only 6 voxels)
%     ds_fmri=cosmo_synthetic_dataset('type','fmri');
%     % by default use NN=3 connectivity (voxels sharing a vertex is
%     % sufficient to be neighbors)
%     nh_fmri=cosmo_cluster_neighborhood(ds_fmri,'progress',false);
%     % each voxel has 4 or 6 neighbors
%     cosmo_disp(nh_fmri.neighbors);
%     > { [ 1         2         4         5 ]
%     >   [ 1         2         3         4         5         6 ]
%     >   [ 2         3         5         6 ]
%     >   [ 1         2         4         5 ]
%     >   [ 1         2         3         4         5         6 ]
%     >   [ 2         3         5         6 ]                     }
%
%     % get neighbors in time-lock MEEG dataset from the neuromag306
%     % system, with combined planar and axial channels
%     ds_meg=cosmo_synthetic_dataset('type','meeg',...
%                          'size','big',...
%                          'sens','neuromag306_planar_combined+axial');
%     nh_meg=cosmo_cluster_neighborhood(ds_meg,'progress',false);
%     % neighbors are seperate for axial channels (odd features)
%     % and planar_combined channels (even features)
%     cosmo_disp(nh_meg.neighbors)
%     > { [ 1         9        53  ...  309       359       363 ]@1x12
%     >   [ 2        10        54  ...  310       360       364 ]@1x12
%     >   [ 3        53        55  ...  359       361       363 ]@1x16
%     >                                      :
%     >   [ 1.07e+03 1.12e+03 1.16e+03 ... 1.37e+03 1.38e+03 1.43e+03 ]@1x12
%     >   [ 1.07e+03 1.12e+03 1.12e+03 ... 1.38e+03 1.42e+03 1.43e+03 ]@1x18
%     >   [ 1.07e+03 1.12e+03 1.12e+03 ... 1.38e+03 1.42e+03 1.43e+03 ]@1x18 }@1428x1
%
%     % get neighbors in EEG dataset, either with clustering over all
%     % feature dimensions (channels x time x freq) or with all feature
%     % dimensions except for channels (i.e., time x freq)
%     ds_eeg=cosmo_synthetic_dataset('type','timefreq',...
%                               'size','normal',...
%                               'sens','eeg1005');
%     % neighborhood with clustering over chan x time x freq
%     nh_eeg_full=cosmo_cluster_neighborhood(ds_eeg,'progress',false);
%     % each feature has up to 18 neighbors
%     cosmo_disp(nh_eeg_full.neighbors)
%     > { [ 1         2         3  ...  10       11       12 ]@1x12
%     >   [ 1         2         3  ...  10       11       12 ]@1x12
%     >   [ 1         2         3  ...  10       11       12 ]@1x12
%     >                                :
%     >   [ 19        20        21  ...  28       29       30 ]@1x12
%     >   [ 19        20        21  ...  28       29       30 ]@1x12
%     >   [ 19        20        21  ...  28       29       30 ]@1x12 }@30x1
%     %
%     % neighborhood with clustering over time x freq (not over chan)
%     nh_eeg_tf=cosmo_cluster_neighborhood(ds_eeg,'progress',false,...
%                                                 'chan',false);
%     % each feature has at most 6 neighbors
%     cosmo_disp(nh_eeg_tf.neighbors)
%     > { [ 1         4         7        10 ]
%     >   [ 2         5         8        11 ]
%     >   [ 3         6         9        12 ]
%     >                    :
%     >   [ 19        22        25        28 ]
%     >   [ 20        23        26        29 ]
%     >   [ 21        24        27        30 ] }@30x1
%
%
% NNO Jan 2015


    % set defaults
    default=struct();
    default.progress=true;
    opt=cosmo_structjoin(default,varargin{:});

    % check dataset
    cosmo_check_dataset(ds);

    % get neighborhoods for each individual dimension
    nbrhoods=get_dimension_neighborhoods(ds,opt);

    % cross the neighborhoods to get full neighborhood
    full_nbrhood=cosmo_cross_neighborhood(ds,nbrhoods,opt);

    % determine mapping from all feature attributes to only those in the
    % dataset
    ds2nbrhood=get_dataset2neighborhood_mapping(ds, full_nbrhood);

    % slice nbrhood to match feature attributes
    nbrhood.neighbors=full_nbrhood.neighbors(ds2nbrhood);
    nbrhood.fa=cosmo_slice(full_nbrhood.fa,ds2nbrhood,2,'struct');
    nbrhood.a=ds.a;

    nbrhood=set_feature_sizes(nbrhood);
    check_matching_fa(ds,nbrhood);

function check_matching_fa(ds,nbrhood)
    % ensure that all dimension values in fa match between ds and nbrhood
    labels=ds.a.fdim.labels;
    for k=1:numel(labels)
        label=labels{k};
        assert(isequal(ds.fa.(label),nbrhood.fa.(label)));
    end

function nbrhood=set_feature_sizes(nbrhood)
    % set feature sizes if not set
    if ~isfield(nbrhood.fa,'sizes')
        nfeatures=numel(nbrhood.neighbors);
        nbrhood.fa.sizes=ones(1,nfeatures);
    end

function ds2nbrhood=get_dataset2neighborhood_mapping(ds, nbrhood)
    % ensure matching .fa for ds and nbrhood
    assert(isequal(nbrhood.a.fdim.values(:),ds.a.fdim.values(:)));
    assert(isequal(nbrhood.a.fdim.labels(:),ds.a.fdim.labels(:)));

    dim_labels=ds.a.fdim.labels;
    dim_sizes=cellfun(@numel,ds.a.fdim.values);
    ndim=numel(dim_labels);

    % store fa indices
    ds_fa=cell(1,ndim);
    nbrhood_fa=cell(1,ndim);
    for dim=1:ndim
        ds_fa{dim}=ds.fa.(dim_labels{dim});
        nbrhood_fa{dim}=nbrhood.fa.(dim_labels{dim});
    end

    % convert to linear indices
    if ndim==1
        % trivial case
        ds_lin=ds_fa{1};
        nbrhood_lin=nbrhood_fa{1};
    else
        ds_lin=sub2ind(dim_sizes, ds_fa{:});
        nbrhood_lin=sub2ind(dim_sizes, nbrhood_fa{:});
    end

    % total number of features in cross product
    n=prod(dim_sizes);

    % mapping from all features to those in nbrhood
    full2nbrhood=zeros(1,n);
    full2nbrhood(nbrhood_lin)=1:numel(nbrhood_lin);

    % ensure that nbrhood has no features not in ds
    ds2nbrhood=full2nbrhood(ds_lin);
    if any(ds2nbrhood==0)
        idx=find(ds2nbrhood==0,1);
        error('Missing neighborhood in dataset feature #%d',idx);
    end


function nbrhoods=get_dimension_neighborhoods(ds,opt)
    % get neighborhoods for each feature dimension

    dim_labels=ds.a.fdim.labels;
    n=numel(dim_labels);

    % keep track of which
    visited=false(n,1);
    nbrhoods=cell(n,1);


    while true
        i=find(~visited,1);

        if isempty(i)
            % all done
            break;
        end

        dim_label=dim_labels{i};
        other_dim_labels={};
        switch dim_label
            case 'i'
                dim_type='fmri';
                neighborhood_func=@fmri_neighborhood;
                other_dim_labels={'j','k'};
            case 'node_indices'
                dim_type='surface';
                neighborhood_func=@surface_neighborhood;
            case 'chan'
                dim_type='chan';
                neighborhood_func=@chan_neighborhood;
            otherwise
                dim_type=dim_label;
                neighborhood_func=@interval_neighborhood;
        end

        % see if option is specified for this dimension label
        has_dim_opt=isfield(opt,dim_type);
        if has_dim_opt
            dim_opt=opt.(dim_type);
        else
            dim_opt=[];
        end

        if isstruct(dim_opt)
            % neighborhood struct, use directly
            cosmo_check_neighborhood(dim_opt);
            nbrhood=dim_opt;
        else
            % compute neighborhood
            radius=dim_opt;
            if ~(isempty(radius) || (isscalar(radius) && radius>=0))
                error('radius for %s must be non-negative scalar',...
                        dim_type)
            end
            nbrhood=neighborhood_func(ds,i,radius,opt);
        end

        nbrhoods{i}=nbrhood;

        visited_dim_labels=[{dim_label} other_dim_labels];
        visited(cosmo_match(dim_labels,visited_dim_labels))=true;
    end

    msk=~cellfun(@isempty,nbrhoods);
    nbrhoods=nbrhoods(msk);



function nbrhood=fmri_neighborhood(ds,dim_pos,connectivity,opt)
    if isempty(connectivity)
        connectivity=3; % NN=3 connectivity
    end

    if ~isnumeric(connectivity) || ~any(connectivity==1:3)
        error('argument for ''fmri'' must be 1, 2 or 3');
    end

    radius=sqrt(connectivity)+.001;

    dim_labels=ds.a.fdim.labels;
    assert(isequal(ds.a.fdim.labels{dim_pos},'i'));

    if numel(dim_labels)>(dim_pos+2) || ...
            ~isequal(dim_labels,{'i','j','k'})
        error(['expected dataset with .a.fdim.labels([%d,%d,%d])='...
                '{''i'',''j'',''k''}. \n'...
                '- If this is an fMRI dataset, it seems messed up\n'...
                '- Otherwise, ''i'' is an illegal a dimension label'],...
                dim_pos,dim_pos+1,dim_pos+2);
    end


    nbrhood=cosmo_spherical_neighborhood(ds,'radius',radius,opt);

    % only keep i, j and k feature attributes
    keep_fa={'i','j','k'};
    keys=fieldnames(nbrhood.fa);
    i=find(~cosmo_match(keys,keep_fa));
    for j=1:numel(i)
        key=keys{j};
        nbrhood.fa=rmfield(nbrhood.fa,key);
    end


function nbrhood=chan_neighborhood(ds,dim_pos,arg,unused)
    do_connect=get_default_connect(arg);

    assert(isequal(ds.a.fdim.labels{dim_pos},'chan'));
    nbrhood=cosmo_meeg_chan_neighborhood(ds,'chantype','all',...
                                            'label','dataset',...
                                            'delaunay',do_connect);


function nbrhood=surface_neighborhood(ds,dim_pos,arg,opt)
    do_connect=get_default_connect(arg,'surface');

    assert(isequal(ds.a.fdim.labels{dim_pos},'node_indices'));

    if ~all(cosmo_isfield(opt,{'vertices','faces'}))
        error(['for surfaces, use the syntax\n\n',...
                '  %s(''vertices'',v,''faces'',f)\n' ,...
                'to specify the coordinates v and the faces f'],...
                mfilename());
    end

    surf_def={opt.vertices,opt.faces};
    cosmo_check_external('surfing');
    nbrhood=cosmo_surficial_neighborhood(ds,surf_def,...
                                    'direct',do_connect,opt);


    node_area_surf=surfing_surfacearea(opt.vertices,opt.faces);
    feature_ids=ds.fa.node_indices(ds.a.fdim.values{dim_pos});
    node_area_ds=node_area_surf(feature_ids);

    nbrhood.fa.sizes=node_area_ds';


function nbrhood=interval_neighborhood(ds,dim_pos,arg,unused)
    dim_label=ds.a.fdim.labels{dim_pos};
    do_connect=get_default_connect(arg,dim_label);

    nbrhood=cosmo_interval_neighborhood(ds,dim_label,'radius',do_connect);


function do_connect=get_default_connect(arg, label)
    % helper, returns true by default. requires arg to be logical to
    % override
    if isempty(arg)
        % delaunay
        do_connect=true;
    else
        if ~islogical(arg)
            error('argument for ''%s'' must be logical', label);
        end
        do_connect=arg;
    end












