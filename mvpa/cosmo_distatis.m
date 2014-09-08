function res=cosmo_statis(ds, varargin)
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
%    'split_by', s    sample attribute that discriminates chunks (subjects)
%                     (default: 'chunks')
%    'shape', sh      shape of output, 'square' (default) or 'triangle'
%
% Returns:
%    res              result dataset struct with feature-wise optimal
%                     compromise distance matrix across subjects
%      .samples
%
%
% Example:
%     ds=cosmo_synthetic_dataset('nsubjects',5,'nchunks',1,'ntargets',4);
%     % each subject is a chunk
%     ds.sa.chunks=ds.sa.subject;
%     % compute DSM for each subject
%     opt=struct();
%     opt.progress=false;
%     opt.radius=1;
%     sp=cosmo_split(ds,'chunks');
%     for k=1:numel(sp)
%         sp{k}=cosmo_searchlight(sp{k},@cosmo_dissimilarity_matrix_measure,opt);
%         sp{k}.sa.chunks=ones(6,1)*k;
%     end
%     % merge results
%     dsms=cosmo_stack(sp);
%     %
%     r=cosmo_distatis(dsms,'return','distance','progress',false);
%     cosmo_disp(r);
%     > .samples
%     >   [     0         0         0         0         0         0
%     >     0.558     0.658      1.35     0.837      1.34      1.13
%     >     0.614      1.44      1.48     0.849      1.07      1.37
%     >       :         :         :         :         :         :
%     >     0.577     0.972     0.667     0.362     0.576     0.637
%     >      1.22      1.04     0.666     0.899      1.04     0.425
%     >         0         0         0         0         0         0 ]@16x6
%     > .fa
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
%     >     [ 1         1         1         1         1         1 ]
%     >   .quality
%     >     [ 0.49     0.676     0.718     0.488     0.724     0.691 ]
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'i'  'j'  'k' }
%     >     .values
%     >       { [ 1         2         3 ]  [ 1         2 ]  [ 1 ] }
%     >   .vol
%     >     .mat
%     >       [ 10         0         0         0
%     >          0        10         0         0
%     >          0         0        10         0
%     >          0         0         0         1 ]
%     >     .dim
%     >       [ 3         2         1 ]
%     >   .sdim
%     >     .labels
%     >       { 'targets1'  'targets2' }
%     >     .values
%     >       { [ 1    [ 1
%     >           2      2
%     >           3      3
%     >           4 ]    4 ] }
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
%     the
%   - Output can be reshape to matrix or array form using
%     cosmo_unflatten(res,1)
%
% NNO Sep 2014

cosmo_check_external('distatis');

defaults.return='distance';
defaults.split_by='chunks';
defaults.shape='square';
defaults.mask_output=[];
defaults.progress=100;

opt=cosmo_structjoin(defaults,varargin);

if isstruct(ds)
    subject_cell=cosmo_split(ds,opt.split_by);
else
    subject_cell=ds;
end

[dsms,nclasses,dim_labels,dim_values]=get_dsms(subject_cell);

nsubj=numel(subject_cell);
nfeatures=size(ds.samples,2);
quality=zeros(1,nfeatures);

prev_msg='';
clock_start=clock();
show_progress=nfeatures>1 && opt.progress;

for k=1:nfeatures
    x=zeros(nclasses*nclasses,nsubj);
    for j=1:nsubj
        dsm=dsms{j}(:,:,k);
        x(:,j)=distance2crossproduct(dsm);
    end

    c=cosmo_corr(x);

    [e,v]=eigs(c,1);
    ew=e/sum(e);

    compromise=x*ew;

    switch opt.return
        case 'crossproduct'
            result=compromise;
        case 'distance'
            result=crossproduct2distance(compromise);
        otherwise
            error('illegal opt.return');
    end

    if k==1
        % allocat space
        nsamples=zeros(numel(result),nfeatures);
    end

    samples(:,k)=result;
    quality(:,k)=v/nsubj;


    if show_progress && (k<10 || mod(k, opt.progress)==0 || k==nfeatures)
        status=sprintf('quality=%.3f%% (avg)',mean(quality(1:k)));
        prev_msg=cosmo_show_progress(clock_start,k/nfeatures,...
                                                    status,prev_msg);
    end
end


res=struct();

switch opt.shape
    case 'triangle'
        [msk,i,j]=distance_matrix_mask(nclasses);
        res.samples=samples(msk(:),:);
    case 'square'
        res.samples=samples;
        [i,j]=find(ones(nclasses));
    otherwise
        error('unsupported direction %s', opt.shape);
end

if isfield(ds,'fa')
    res.fa=ds.fa;
end
res.fa.quality=quality;
if isfield(ds,'a')
    res.a=ds.a;
end
res.a.sdim=struct();
res.a.sdim.labels=dim_labels;
res.a.sdim.values=dim_values;

res.sa.(dim_labels{1})=i;
res.sa.(dim_labels{2})=j;


function z=crossproduct2distance(x)
    n=sqrt(numel(x));
    e=ones(n,1);
    d=x(1:(n+1):end);
    dd=d*e';
    ddt=dd';
    y=dd(:)+ddt(:)-2*x;
    z=ensure_distance_vector(y);


function z_vec=distance2crossproduct(x)
    n=size(x,1);
    e=ones(n,1);
    m=e*(1/n);
    ee=eye(n)-e*m';
    y=-.5*ee*(x+x')*ee';
    z=(1/eigs(y,1))*y(:);

    z_vec=z(:);


function y=ensure_distance_vector(x)
    tolerance=1e-8;

    n=sqrt(numel(x));
    xsq=reshape(x,n,n);

    dx=diag(xsq);
    assert(all(dx<tolerance));

    xsq=xsq-diag(dx);

    delta=xsq-xsq';
    assert(all(delta(:)<tolerance))

    xsq=.5*(xsq+xsq');
    y=xsq(:);


function [dsms,nclasses,dim_labels,dim_values]=get_dsms(data_cell)
    nsubj=numel(data_cell);

    % allocate
    dsms=cell(nsubj,1);
    for k=1:numel(data_cell)
        data=data_cell{k};

        % get data
        [dsm,dim_labels,dim_values]=get_dsm(data);

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

            % check for compatibility over subjects
            cosmo_stack({cosmo_slice(data,1),cosmo_slice(data_first,1)});
        end
    end

function [msk,i,j]=distance_matrix_mask(nclasses)
    msk=triu(repmat(1:nclasses,nclasses,1),1)'>0;
    [i,j]=find(msk);

function [dsm, dim_labels, dim_values]=get_dsm(data)
    if isstruct(data)
        [dsm,dim_labels,dim_values]=cosmo_unflatten(data,1);
    elseif isnumeric(dsm)
        n=size(dsm,1);

        side=(1+sqrt(1+8*n))/2;
        if ~isequal(side, round(side))
            error(['size %d of input vector is not correct for '...
                    'the number of elements below diagonal of a '...
                    'square matrix'], n);
        end

        dim_labels={'targets1','targets2'};
        dim_values={1:n,1:n};
    else
        error('illegal input: expect dataset struct, or cell with arrays');
    end





