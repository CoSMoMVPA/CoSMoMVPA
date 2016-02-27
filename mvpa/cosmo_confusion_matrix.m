function [confusion_matrix, classes]=cosmo_confusion_matrix(ds, varargin)
% Returns a confusion matrix
%
% Usage 1: mx=cosmo_confusion_matrix(ds)
% Usage 2: mx=cosmo_confusion_matrix(targets, predicted)
%
%
% Inputs:
%   targets     Nx1 targets for N samples, or a dataset struct with
%               .sa.targets
%   predicted   NxM predicted labels (from a classifier), for N samples and
%               M predictions per set of samples
%
% Returns:
%   mx          PxPxM matrix assuming there are P unique targets.
%               mx(i,j,k)==c means that the i-th target class was classified
%               as the j-th target class c times for the k-th set of
%               samples.
%   classes     Px1 class labels.
%
% Example:
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4);
%     args=struct();
%     args.partitions=cosmo_nchoosek_partitioner(ds,1);
%     args.output='predictions';
%     args.classifier=@cosmo_classify_lda;
%     pred_ds=cosmo_crossvalidation_measure(ds,args);
%     confusion=cosmo_confusion_matrix(pred_ds.sa.targets,pred_ds.samples);
%     cosmo_disp(confusion)
%     > [ 3         0         1
%     >   0         3         1
%     >   1         0         3 ]
%     confusion_alt=cosmo_confusion_matrix(pred_ds);
%     isequal(confusion,confusion_alt)
%     > true
%     %
%     % run a searchlight with tiny radius of 1 voxel (3 is more common)
%     nbrhood=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
%     measure=@cosmo_crossvalidation_measure;
%     sl_ds=cosmo_searchlight(ds,nbrhood,measure,args,'progress',false);
%     %
%     % the confusion matrix is 3x3x6, that is 6 3x3 confusion
%     % matrices. Here the dataset is passed directly
%     sl_confusion=cosmo_confusion_matrix(sl_ds);
%     cosmo_disp(sl_confusion)
%     > <double>@3x3x6
%     >    (:,:,1) = [ 4         0         0
%     >                0         4         0
%     >                0         1         3 ]
%     >    (:,:,2) = [ 4         0         0
%     >                0         4         0
%     >                0         1         3 ]
%     >    (:,:,3) = [ 2         1         1
%     >                0         4         0
%     >                1         0         3 ]
%     >    (:,:,4) = [ 4         0         0
%     >                0         3         1
%     >                0         1         3 ]
%     >    (:,:,5) = [ 3         0         1
%     >                0         4         0
%     >                1         1         2 ]
%     >    (:,:,6) = [ 3         0         1
%     >                0         4         0
%     >                1         1         2 ]
%
%     % using samples that are not predictions gives an error
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4);
%     confusion=cosmo_confusion_matrix(ds)
%     > error('72 predictions mismatch targets, first is (1,1)=2.211999e+00')
%
% Notes:
%   - this function counts the number of times each sample was classified
%     as any target
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    [targets,predicted]=get_data(ds,varargin{:});

    % see which classes there are
    [class_indices,classes]=cosmo_index_unique(targets);
    nclasses=numel(class_indices);

    % allocate space for output
    nfeatures=size(predicted,2);
    confusion_matrix=zeros([nclasses,nclasses,nfeatures]);

    % keep track which predicted samples were in targets
    visited=false(size(predicted));
    % >@@>
    for k=1:nclasses
        % rows for k-th class
        idxs=class_indices{k};
        for j=1:nclasses
            match_msk=bsxfun(@eq,classes(j),predicted(idxs,:));
            confusion_matrix(k,j,:)=sum(match_msk,1);
            visited(idxs,:)=visited(idxs,:) | match_msk;
        end
    end

    % <@@<

    missing=~(visited | isnan(predicted));
    if any(missing(:))
        n=sum(missing(:));
        [i,j]=find(missing,1);
        error(['%d predictions mismatch targets, '...
                'first is (%d,%d)=%d'],n,i,j,predicted(i,j));
    end




function [targets,predicted]=get_data(ds, predicted)
    has_predicted=nargin>=2;
    is_ds=isstruct(ds);
    if is_ds
        if has_predicted
            error('Need exactly one argument when input is struct');
        end
        % input is a dataset
        cosmo_isfield(ds,'sa.targets',true);
        cosmo_isfield(ds,'samples',true);

        predicted=ds.samples;
        targets=ds.sa.targets;
    elseif isnumeric(ds)
        if ~has_predicted
            error('Need two arguments when first argument is numeric');
        end
        targets=ds;
    else
        error('Illegal input: need struct or numeric vector');
    end

    if ~isvector(targets) || size(targets,2)~=1
        error('targets must be column vector');
    end

    if numel(size(predicted))~=2
        error('predictions must be matrix');
    end

    nsamples=numel(targets);
    if size(predicted,1)~=nsamples
        error(['Size mismatch: predictions has %d values on first '...
                'dimension, but targets has %d values'],...
                    size(predicted,1),nsamples);
    end

