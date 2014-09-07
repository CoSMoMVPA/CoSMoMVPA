function res=cosmo_statis(ds, varargin)
% apply DISTATIS measure to each feature
%
% res=cosmo_statis_measure(ds, opt)
%
% Inputs:
%    ds               dataset struct with dissimilarity measure; usually
%                     the output from @cosmo_dissimilarity_matrix_measure
%                     applied to each subject followed by cosmo_stack
%    'return', d      d can be 'distance' (default) or 'crossproduct'
%    'split_by', s    sample attribute that discriminates subject
%                     (default: 'subject')
%    'direction', dr  direction in which squareform is set: either
%                     'tomatrix' (default) or 'tovector'.
%
% Returns:
%    res              result dataset struct with feature-wise optimal
%                     compromise distance matrix across subjects
%
%
%
%
% Example:
%     ds=cosmo_synthetic_dataset('nsubjects',5,'nchunks',1,'ntargets',4);
%     % compute DSM for each subject
%     opt=struct();
%     opt.progress=false;
%     opt.radius=1;
%     sp=cosmo_split(ds,'subject');
%     for k=1:numel(sp)
%         sp{k}=cosmo_searchlight(sp{k},@cosmo_dissimilarity_matrix_measure,opt);
%         sp{k}.sa.subject=ones(6,1)*k;
%     end
%     % merge results
%     dsms=cosmo_stack(sp);
%     %
%     r=cosmo_distatis(dsms,'return','distance');
%     cosmo_disp(r);
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
%     > .samples
%     >   [     0         0         0         0         0         0
%     >     0.558     0.658      1.35     0.837      1.34      1.13
%     >     0.614      1.44      1.48     0.849      1.07      1.37
%     >       :         :         :         :         :         :
%     >     0.577     0.972     0.667     0.362     0.576     0.637
%     >      1.22      1.04     0.666     0.899      1.04     0.425
%     >         0         0         0         0         0         0 ]@16x6
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
defaults.split_by='subject';
defaults.direction='tomatrix';
defaults.mask_output=[];

opt=cosmo_structjoin(defaults,varargin);

if isstruct(ds)
    subject_cell=cosmo_split(ds,opt.split_by);
else
    subject_cell=ds;
end

[dsms,nclasses,dim_labels,dim_values]=get_dsms(subject_cell);

nsubj=numel(subject_cell);
nfeatures=size(ds.samples,2);
q=zeros(1,nfeatures);

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
        nsamples=zeros(numel(result),nfeatures);
    end

    samples(:,k)=result;
    q(:,k)=v/nsubj;
end


res=struct();
if isfield(ds,'fa')
    res.fa=ds.fa;
end
res.fa.quality=q;
if isfield(ds,'a')
    res.a=ds.a;
end
res.a.sdim=struct();
res.a.sdim.labels=dim_labels;
res.a.sdim.values=dim_values;

switch opt.direction
    case 'tovector'
        msk=triu(repmat(1:nclasses,nclasses,1),1)'>0;
        res.samples=samples(msk(:),:);
        [i,j]=find(msk);
    case 'tomatrix'
        res.samples=samples;
        [i,j]=find(ones(nclasses));
    otherwise
        error('unsupported mask_output %s', mask_output);
end

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


function [dsms,nclasses,dim_labels,dim_values]=get_dsms(sp)
    nsubj=numel(sp);

    dsms=cell(nsubj,1);
    for k=1:numel(sp)
        [dsm,dim_labels,dim_values]=cosmo_unflatten(sp{k},1);
        dsms{k}=dsm;
        if k==1
            nclasses=size(dsm,1);
            first_dim_labels=dim_labels;
            first_dim_values=dim_values;
        else

            if ~isequal(first_dim_labels,dim_labels)
                error('dim label mismatch between subject 1 and %d',k);
            end
            if ~isequal(first_dim_values,dim_values)
                error('dim label mismatch between subject 1 and %d',k);
            end

            % check for compatibility over subjects
            cosmo_stack({cosmo_slice(sp{k},1),cosmo_slice(sp{1},1)});
        end
    end

