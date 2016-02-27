function res=cosmo_distatis(ds, varargin)
% apply DISTATIS measure to each feature
%
% res=cosmo_statis_measure(ds, opt)
%
% Inputs:
%    ds               dataset struct with dissimilarity values; usually
%                     the output from @cosmo_dissimilarity_matrix_measure
%                     applied to each subject followed by cosmo_stack. It
%                     can also be a cell with datasets (one per subject).
%    'return', d      d can be 'distance' (default) or 'crossproduct'.
%                     'distance' returns a distance matrix, whereas
%                     'crossproduct' returns a crossproduct matrix
%    'split_by', s    sample attribute that discriminates chunks
%                     (participants) (default: 'chunks')
%    'shape', sh      shape of output if it were unflattened using
%                     cosmo_unflatten, either 'square' (default) or
%                     'triangle' (which gives the lower diagonal of the
%                     distance matrix)
%
% Returns:
%    res              result dataset struct with feature-wise optimal
%                     compromise distance matrix across subjects
%      .samples
%
%
% Example:
%     ds=cosmo_synthetic_dataset('nsubjects',5,'nchunks',1,'ntargets',4);
%     %
%     % define neighborhood (here a searchlight with radius of 1 voxel)
%     nbrhood=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
%     %
%     % define measure
%     measure=@cosmo_dissimilarity_matrix_measure;
%     % each subject is a chunk
%     ds.sa.chunks=ds.sa.subject;
%     % compute DSM for each subject
%     sp=cosmo_split(ds,'chunks');
%     for k=1:numel(sp)
%         sp{k}=cosmo_searchlight(sp{k},nbrhood,measure,'progress',false);
%         sp{k}.sa.chunks=ones(6,1)*k;
%     end
%     % merge results
%     dsms=cosmo_stack(sp);
%     %
%     r=cosmo_distatis(dsms,'return','distance','progress',false);
%     cosmo_disp(r);
%     > .samples
%     >   [     0         0         0         0         0         0
%     >     0.818      1.09      0.77     0.653      1.03     0.421
%     >     0.869       1.3      1.06      1.04     0.932      1.07
%     >       :         :         :         :         :         :
%     >      1.16     0.889      0.99     0.631      1.48     0.621
%     >     0.268     0.952     0.965     0.462     0.943      1.04
%     >         0         0         0         0         0         0 ]@16x6
%     > .fa
%     >   .center_ids
%     >     [ 1         2         3         4         5         6 ]
%     >   .i
%     >     [ 1         2         3         1         2         3 ]
%     >   .j
%     >     [ 1         1         1         2         2         2 ]
%     >   .k
%     >     [ 1         1         1         1         1         1 ]
%     >   .nvoxels
%     >     [ 3         4         3         3         4         3 ]
%     >   .radius
%     >     [ 1         1         1         1         1         1 ]
%     >   .quality
%     >     [ 0.685     0.742     0.617     0.648     0.757     0.591 ]
%     >   .nchunks
%     >     [ 5         5         5         5         5         5 ]
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'i'  'j'  'k' }
%     >     .values
%     >       { [ 1         2         3 ]  [ 1         2 ]  [ 1 ] }
%     >   .sdim
%     >     .labels
%     >       { 'targets1'  'targets2' }
%     >     .values
%     >       { [ 1    [ 1
%     >           2      2
%     >           3      3
%     >           4 ]    4 ] }
%     >   .vol
%     >     .mat
%     >       [ 2         0         0        -3
%     >         0         2         0        -3
%     >         0         0         2        -3
%     >         0         0         0         1 ]
%     >     .dim
%     >       [ 3         2         1 ]
%     >     .xform
%     >       'scanner_anat'
%     > .sa
%     >   .targets1
%     >     [ 1
%     >       2
%     >       3
%     >       :
%     >       2
%     >       3
%     >       4 ]@16x1
%     >   .targets2
%     >     [ 1
%     >       1
%     >       1
%     >       :
%     >       4
%     >       4
%     >       4 ]@16x1
%
% Reference:
%   - Abdi, H., Valentin, D., O?Toole, A. J., & Edelman, B. (2005).
%     DISTATIS: The analysis of multiple distance matrices. In
%     Proceedings of the IEEE Computer Society: International conference
%     on computer vision and pattern recognition, San Diego, CA, USA
%     (pp. 42?47).
%
% Notes:
%   - DISTATIS tries to find an optimal compromise distance matrix across
%     the different samples (participants)
%   - Output can be reshape to matrix or array form using
%     cosmo_unflatten(res,1)
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    cosmo_check_external('distatis');

    defaults.return='distance';
    defaults.split_by='chunks';
    defaults.shape='square';
    defaults.mask_output=[];
    defaults.progress=100;
    defaults.feature_ids=[];
    defaults.autoscale=true;
    defaults.abs_correlation=false;
    defaults.weights='eig';

    opt=cosmo_structjoin(defaults,varargin);

    subject_cell=get_subject_data(ds,opt);
    nsubj=numel(subject_cell);


    [dsms,nclasses,dim_labels,dim_values]=get_dsms(subject_cell);

    feature_ids=get_feature_ids(size(dsms{1},3),opt);
    nfeatures=numel(feature_ids);

    quality=zeros(1,nfeatures);
    nobservations=zeros(1,nfeatures);

    prev_msg='';
    clock_start=clock();
    show_progress=nfeatures>1 && opt.progress;

    for k=1:nfeatures
        feature_id=feature_ids(k);
        x=zeros(nclasses*nclasses,nsubj);

        for j=1:nsubj
            dsm=dsms{j}(:,:,feature_id);
            x(:,j)=distance2crossproduct(dsm, opt.autoscale);
        end

        [x,subj_msk]=cosmo_remove_useless_data(x);
        nkeep=sum(subj_msk);

        % equivalent, but slower:
        % [e,v]=eigs(c,1);

        [ew,v]=get_weights(x, feature_id, nkeep, opt);

        % compute compromise
        compromise=x*ew;

        result=convert_compromise(compromise, opt);

        if feature_id==1
            % allocate space
            samples=zeros(numel(result),nfeatures);
        end

        samples(:,k)=result;

        quality(:,k)=v/nkeep;
        nobservations(:,k)=nkeep;


        if show_progress && (k<10 || ...
                                mod(k, opt.progress)==0 || ...
                                k==nfeatures)
            status=sprintf('quality=%.3f%% (avg)',mean(quality(1:k)));
            prev_msg=cosmo_show_progress(clock_start,k/nfeatures,...
                                                        status,prev_msg);
        end
    end

    % set output in either triangular or square shape
    [res,i,j]=get_samples_in_shape(samples,nclasses,opt.shape);
    res=copy_fields(ds,res,{'fa','a'});

    % add attributes
    res.fa.quality=quality;
    res.fa.nchunks=nobservations;
    res.a.sdim=struct();
    res.a.sdim.labels=dim_labels;
    res.a.sdim.values=dim_values;

    res.sa.(dim_labels{1})=i(:);
    res.sa.(dim_labels{2})=j(:);

    cosmo_check_dataset(res);

function [res,i,j]=get_samples_in_shape(samples,nclasses,shape)
    res=struct();
    switch shape
        case 'triangle'
            [msk,i,j]=distance_matrix_mask(nclasses);
            res.samples=samples(msk(:),:);
        case 'square'
            res.samples=samples;
            [i,j]=find(ones(nclasses));
        otherwise
            error('unsupported direction %s', shape);
    end



function dst=copy_fields(src,dst,keys)
    for k=1:numel(keys)
        key=keys{k};
        if isfield(src,key)
            dst.(key)=src.(key);
        end
    end


function feature_ids=get_feature_ids(nfeatures, opt)
    feature_ids=opt.feature_ids;
    if isempty(feature_ids);
        feature_ids=1:nfeatures;
    end


function [ew,v]=get_weights(x, feature_id, nkeep, opt)
    switch opt.weights
        case 'eig'
            [ew,v]=eigen_weights(x, feature_id);

        case 'uniform'
            % all the same (allowing for comparison with 'eig')
            ew=ones(nkeep,1)/nkeep;
            v=0;

        otherwise
            error('illegal weight %s', opt.weights);
    end



function subject_cell=get_subject_data(ds,opt)
    if isstruct(ds)
        subject_cell=cosmo_split(ds,opt.split_by);
    else
        subject_cell=ds;
    end

    if numel(subject_cell)==0
        error('empty input');
    end


function [ew,v]=eigen_weights(x, feature_id)

    c=cosmo_corr(x);

    negative_c=c<0;

    if any(negative_c(:))
        [i,j]=find(negative_c);
        error(['feature %d has negative correlation between '...
                'sample %d and %d, which is not supported by '...
                'distatis. DISTATIS assumes that the similarity '...
                'data from all samples (typically: participants) '...
                'correlate positively. Because that is not the '...
                'case, you cannot use DISTATIS analysis on this '...
                'data. '],...
                feature_id,i,j);
    end

    [v,e]=fast_eig1(c);

    if all(e<0)
        e=-e;
    end

    assert(all(e>0));
    assert(v>0);

    % normalize first eigenvector
    ew=e/sum(e);


function result=convert_compromise(compromise, opt)
    switch opt.return
        case 'crossproduct'
            result=compromise;
        case 'distance'
            result=crossproduct2distance(compromise);
        otherwise
            error('illegal opt.return');
    end

function z=crossproduct2distance(x)
    n=sqrt(numel(x));
    e=ones(n,1);
    d=x(1:(n+1):end);
    dd=d*e';
    ddt=dd';
    y=dd(:)+ddt(:)-2*x;
    z=ensure_distance_vector(y);

function assert_symmetric(x, tolerance)
    if nargin<2, tolerance=1e-8; end

    % assert x is a square matrix
    sz=size(x);
    assert(isequal(sz,sz([2 1])));


    xx=x'-x;

    msk=xx>tolerance;
    if any(msk)
        [i,j]=find(msk,1);
        error('not symmetric: x(%d,%d)=%d ~= %d=x(%d,%d)',...
                i,j,x(i,j),x(j,i),j,i);
    end

function z_vec=distance2crossproduct(x, autoscale)

    n=size(x,1);
    e=ones(n,1);
    m=e*(1/n);
    ee=eye(n)-e*m';
    y=-.5*ee*(x+x')*ee';
    if autoscale
        z=(1/fast_eig1(y))*y;
    else
        z=y;
    end
    assert_symmetric(z);
    % equivalent, but slower:
    % z=(1/eigs(y,1))*y(:);

    z_vec=z(:);

function [lambda,pivot]=fast_eig1(x)
    % returns the first eigenvalue in lambda, and the corresponding
    % eigenvector in pivot
    if cosmo_wtf('is_matlab')
        [pivot,lambda]=eigs(x,1);
    else
        % There seems a bug in Octave for 'eigs',
        % so use 'eig' instead.
        % http://savannah.gnu.org/bugs/?44004
        [e,v]=eig(x);
        diag_v=diag(v);

        % find largest eigenvalue and eigenvector
        [lambda,i]=max(diag_v);
        pivot=e(:,i);
    end

    % The code below is disabled because under certain circumstances
    % it would return a near-zero eigenvalue if indeed one eigenvalue (but
    % not the largest one) is zero.
    % % compute first (largest) eigenvalue and corresponding eigenvector
    % % using power iteration method; benchmarking suggests this can be up to
    % % five times as fast as using eigs(x,1)
    % n=size(x,1);
    % pivot=ones(n,1);
    % tolerance=1e-8;
    % max_iter=1000;
    %
    % old_lambda=NaN;
    % for k=1:max_iter
    %     z=x*pivot;
    %     pivot=z / norm(z);
    %
    %     lambda=pivot'*z;
    %     if abs(lambda-old_lambda)/lambda<tolerance
    %         z=x*pivot;
    %         pivot=z / sqrt(sum(z.^2));
    %
    %         lambda=pivot'*z;
    %         return
    %     end
    %     old_lambda=lambda;
    % end
    %
    % % matlab fallback
    % [pivot,lambda]=eigs(x,1);

function y=ensure_distance_vector(x)
    tolerance=1e-8;

    n=sqrt(numel(x));
    xsq=reshape(x,n,n);

    dx=diag(xsq);
    assert(all(dx<tolerance));

    xsq=xsq-diag(dx);

    delta=xsq-xsq';
    assert(all(delta(:)<tolerance));

    xsq=.5*(xsq+xsq');
    y=xsq(:);


function [dsms,nclasses,dim_labels,dim_values]=get_dsms(data_cell)
    nsubj=numel(data_cell);

    % allocate
    dsms=cell(nsubj,1);
    for k=1:numel(data_cell)
        data=data_cell{k};

        % get data
        [dsm,dim_labels,dim_values,is_ds]=get_dsm(data);

        % store data
        dsms{k}=dsm;

        if k==1
            nclasses=size(dsm,1);
            first_dim_labels=dim_labels;
            first_dim_values=dim_values;

            data_first=data;
        else

            if ~isequal(first_dim_labels,dim_labels)
                error('dim label mismatch between subject 1 and %d',k);
            end
            if ~isequal(first_dim_values,dim_values)
                error('dim label mismatch between subject 1 and %d',k);
            end

            % check for compatibility over subjects, raises an error if not
            % kosher
            if is_ds
                cosmo_stack({cosmo_slice(data,1),...
                                cosmo_slice(data_first,1)},1,'unique');
            end
        end
    end

function [msk,i,j]=distance_matrix_mask(nclasses)
    msk=triu(repmat(1:nclasses,nclasses,1),1)'>0;
    [i,j]=find(msk);

function [dsm, dim_labels, dim_values, is_ds]=get_dsm(data)
    is_ds=isstruct(data);
    if is_ds
        [dsm,dim_labels,dim_values]=cosmo_unflatten(data,1);
    elseif isnumeric(data)
        sz=size(data);
        if numel(sz)~=2
            error('only vectorized distance matrices are supported');
        end
        [n,nfeatures]=size(data);

        side=(1+sqrt(1+8*n))/2; % so that side*(side-1)/2==n
        if ~isequal(side, round(side))
            error(['size %d of input vector is not correct for '...
                    'the number of elements below the diagonal of a '...
                    'square (distance) matrix'], n);
        end

        [msk,i,j]=distance_matrix_mask(side);
        dsm=zeros([side,side,nfeatures]);

        assert(numel(i)==n);
        for pos=1:n
            dsm(i(pos),j(pos),:)=data(pos,:);
        end

        sq1=cosmo_squareform(data(:,1));
        dsm1=dsm(:,:,1);
        assert(isequal(sq1,dsm1+dsm1'));


        dim_labels={'targets1','targets2'};
        dim_values={(1:side)',(1:side)'};
    else
        error('illegal input: expect dataset struct, or cell with arrays');
    end





