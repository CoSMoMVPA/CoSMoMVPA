function [nh_split,masks]=cosmo_neighborhood_split(nh, varargin)
% partitions a neighborhood in a cell with (smaller) neigborhoods
%
% cosmo_neighborhood_split(nh, ...)
%
% Inputs:
%   nh                  neighborhood struct with fields .neighbors and
%                       .origin
%   'divisions', d      Number of divisions along each feature dimension.
%                       For example, if d=4 for an fMRI dataset (with
%                       three feature dimensions corresponding to the three
%                       spatial dimension, then the output will have
%                       at most 4^3=64 neighborhood structs and masks.
%
% Output:
%   nh_split            Cell with neighborhood structs. When all elements
%                       in nh_split are combined they should contain the
%                       same information in .neighbors and .fa as in the
%                       input nh, but with a re-indexing of the feature ids
%                       corresponding to the masks.
%   masks               Cell with mask datasets, corresponding to the
%                       features returned in neighborhoods in nh_split.
%                       When the dataset derived from the input
%                       neighborhood nh is masked by the k-th mask, then
%                       the indices in the resulting dataset match the
%                       indices in .neighbors
%
%
% Example:
%     % the following example shows how a neighborhood can be split in
%     % parts, a searchlight run on each part, and the different outputs
%     % joined together. This gives identical results as running the
%     % searchlight on the entire dataset
%     %
%     % generate a tiny dataset with 6 voxels
%     ds=cosmo_synthetic_dataset();
%     %
%     % define tiny neighborhoods with radii of 1 voxel
%     % (more typical values are ~3 voxels)
%     nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
%     %
%     % Use a simple 'measure' that just averages data along the feature
%     % dimension. (Any other measure can be used as well)
%     averager=@(x,opt)cosmo_structjoin('samples',mean(x.samples,2));
%     %
%     % disable progress reporting for the searchlight
%     opt=struct();
%     opt.progress=false;
%     %
%     % run the searchlight
%     result=cosmo_searchlight(ds,nh,averager,opt);
%     %
%     % show output from searchlight
%     cosmo_disp({result.samples; result.fa});
%     > { [ 0.768     0.368        -1      1.45    0.0342     -0.32
%     >     0.526      1.77     0.937      1.08      1.07      1.49
%     >      0.46     -1.25    -0.152    0.0899     0.795    -0.522
%     >      1.23     0.685     0.954     0.606      1.19     0.335
%     >     0.914   -0.0442    0.0295     0.664     0.274    -0.221
%     >     0.633      1.24     0.797     0.861      1.54      1.02 ]
%     >   .nvoxels
%     >     [ 3         4         3         3         4         3 ]
%     >   .radius
%     >     [ 1         1         1         1         1         1 ]
%     >   .center_ids
%     >     [ 1         2         3         4         5         6 ]
%     >   .i
%     >     [ 1         2         3         1         2         3 ]
%     >   .j
%     >     [ 1         1         1         2         2         2 ]
%     >   .k
%     >     [ 1         1         1         1         1         1 ]   }
%     %
%     [nh_splits,masks_split]=cosmo_neighborhood_split(nh);
%     n_split=numel(nh_splits);
%     %
%     % Allocate space for searchlight output from each part
%     res2_cell=cell(1,n_split);
%     %
%     for k=1:n_split
%         % get the k-th neighborhood
%         nh_sel=nh_splits{k};
%         %
%         % slice the dataset to select only the features indexed by
%         % the nh_sel neighborhood.
%         %
%         % (when using fmri datasets, it is also possible to use
%         %  cosmo_fmri_dataset with a filename and the mask from masks,
%         %  as in:
%         %
%         %     ds_sel=cosmo_fmri_dataset('data.nii','mask',masks_split{k});
%         %
%         %  Such an approach may result in significant reduction of memory
%         %  usage, if the file format supports loading partial files
%         %  (currently unzipped NIFTI (.nii), ANALYZE (.hdr) and AFNI)))
%         ds_sel=cosmo_slice(ds,masks_split{k}.samples,2);
%         %
%         % run the searchlight for this split, and store the result
%         res2_cell{k}=cosmo_searchlight(ds_sel,nh_sel,averager,opt);
%     end
%     %
%     % join the results along the second (feature) dimension
%     result2=cosmo_stack(res2_cell,2);
%     %
%     % show the results; they are identical to the original output, modulo
%     % a possible permutation of the features.
%     cosmo_disp({result2.samples; result2.fa});
%     > { [ 0.768     0.368      1.45    0.0342        -1     -0.32
%     >     0.526      1.77      1.08      1.07     0.937      1.49
%     >      0.46     -1.25    0.0899     0.795    -0.152    -0.522
%     >      1.23     0.685     0.606      1.19     0.954     0.335
%     >     0.914   -0.0442     0.664     0.274    0.0295    -0.221
%     >     0.633      1.24     0.861      1.54     0.797      1.02 ]
%     >   .center_ids
%     >     [ 1         2         3         4         1         2 ]
%     >   .i
%     >     [ 1         2         1         2         3         3 ]
%     >   .j
%     >     [ 1         1         2         2         1         2 ]
%     >   .k
%     >     [ 1         1         1         1         1         1 ]
%     >   .nvoxels
%     >     [ 3         4         3         4         3         3 ]
%     >   .radius
%     >     [ 1         1         1         1         1         1 ]   }
%
%
% Notes:
%   - typical use cases of this function are:
%     * searchlights on fMRI dataset with many samples and features
%       (i.e. too many to load all of them in memory). In this case, and
%       if the file format supports it (NIFTI, ANALYZE, AFNI), parts
%       of the data can be loaded with cosmo_fmri_datset, where the masks
%       are based on the second output from this function
%     * parallel searchlights on a cluster using multiple computing nodes.
%
% See also: cosmo_searchlight, cosmo_fmri_dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults=struct();
    defaults.divisions=4;

    opt=cosmo_structjoin(defaults,varargin);
    validate_input(nh, opt);

    % see how big each block is along each dimension
    [first,last,nfeatures]=get_dim_range(nh);

    min_first=min(first,[],2);
    max_last=max(last,[],2);
    max_size=max(last-first,[],2)+1;
    extent=max_last-min_first+1;

    % Examples of how max_size, step and extent are related:
    % max_size=1, step=5, extent=25, 5 div: 1-5, 6-10, 11-15, 16-20, 21-25
    % max_size=1, step=4, extent=20, 5 div: 1-4,  5-8,  9-12, 13-16, 17-20
    % max_size=2, step=5, extent=26, 5 div: 1-6, 6-11, 11-16, 16-21, 21-26
    % max_size=2, step=4, extent=21, 5 div: 1-5,  5-9,  9-13, 13-17, 17-21
    % max_size=3, step=4, extent=22, 5 div: 1-6, 5-10,  9-14, 13-18, 17-22

    % first element:                step+max_size-1     elements
    % all other (div-1) elements:   step                elements

    step=ceil((extent+1-max_size)/opt.divisions);
    assert(all(step>=1));

    % for each element in nh.neighbors, assign it to a block
    % indexed by ndim integers (where ndim is the number of dimensions)
    dim_pos=floor(bsxfun(@rdivide,first-1,step))+1;

    % get the indices for each block.
    % idxs{k}=[a_k1, ..., a_kN] means that nh.neighbors{a_k1}, ...,
    % nh.neighbors{a_kN} all refer to neighboring features
    %
    [idxs,unq]=cosmo_index_unique(dim_pos');

    nsplit=size(unq,1);

    nh_split=cell(nsplit,1);
    masks=cell(nsplit,1);

    keep_split_mask=false(nsplit,1);

    for split_id=1:nsplit
        msk=false(1,nfeatures);
        idx=idxs{split_id};
        n_nbrs=numel(idx);
        for j=1:n_nbrs
            nb=nh.neighbors{idx(j)};
            msk(1,nb)=true;
        end

        if ~any(msk)
            % skip empty neighbors
            continue;
        end

        keep_split_mask(split_id)=true;


        m_k=struct();
        m_k.samples=msk;
        m_k.a=nh.origin.a;
        m_k.fa=nh.origin.fa;

        nh_k=struct();
        nh_k.origin.a=m_k.a;
        nh_k.origin.fa=cosmo_slice(m_k.fa,msk,2,'struct');
        nh_k.a=nh.a;
        nh_k.fa=cosmo_slice(nh.fa, idx, 2, 'struct');

        all2some=zeros(1,nfeatures);
        all2some(msk)=1:sum(msk);
        neighbors=cell(n_nbrs,1);
        for j=1:n_nbrs
            some=all2some(nh.neighbors{idx(j)});
            assert(all(some~=0));
            neighbors{j}=some;
        end
        nh_k.neighbors=neighbors;

        nh_split{split_id}=nh_k;
        masks{split_id}=m_k;
    end

    % only keep non-empty masks
    nh_split=nh_split(keep_split_mask);
    masks=masks(keep_split_mask);


function [first,last,nfeatures]=get_dim_range(nh)
    % for each feature dimension, find the minimum and maximum value
    % in each neighborhood
    % If nh has N neighbors and M dimensions, then the output of first and
    % last in M x N.
    fdim=nh.origin.a.fdim;
    labels=fdim.labels;

    n_labels=numel(labels);
    n_neighbors=numel(nh.neighbors);

    fa=nh.origin.fa;

    % pre-store values for each feature attribute
    fa_idxs_cell=cell(n_labels,1);

    for k=1:n_labels
        label=labels{k};
        fa_idxs=fa.(label);
        fa_idxs_cell{k}=fa_idxs;
    end

    first=zeros(n_labels,n_neighbors);
    last=zeros(n_labels,n_neighbors);
    nfeatures=0;



    for j=1:n_neighbors
        nb=nh.neighbors{j};

        mx_nb=max(nb);
        if mx_nb>nfeatures
            nfeatures=mx_nb;
        end

        for k=1:n_labels
            % (this is a timing-critical part of the loop)
            nb_values=fa_idxs_cell{k}(nb);

            first(k,j)=min(nb_values);
            last(k,j)=max(nb_values);
        end
    end


function opt=validate_input(nh, opt)
    % some checks on the input
    cosmo_check_neighborhood(nh);

    allowed_fieldnames={'divisions'};
    delta=setdiff(fieldnames(opt), allowed_fieldnames);
    if ~isempty(delta)
        error('illegal field %s', delta{1});
    end

    divisions=opt.divisions;
    if ~(isnumeric(divisions) && ...
                isscalar(divisions) && ...
                isfinite(divisions) && ...
                divisions > 1)
        error('count must be finite scalar >1');
    end


    origin_labels={'origin.fa',...
                    'origin.a.fdim.labels',...
                    'origin.a.fdim.values'};
    if ~all(cosmo_isfield(nh,origin_labels))
        error('origin has missing labels');
    end

    is_numeric_vector=@(x)isnumeric(x) && isvector(x);
    if ~all(cellfun(is_numeric_vector, nh.a.fdim.values))
        error('elements in .a.fdim.values must be numeric vectors');
    end



