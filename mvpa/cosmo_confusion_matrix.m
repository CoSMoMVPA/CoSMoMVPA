function [confusion_matrix, classes]=cosmo_confusion_matrix(targets, predicted)
% Returns a confusion matrix
%
% mx=cosmo_confusion_matrix(targets, predicted)
%
% Inputs:
%   targets     Nx1 targets for N samples, or a dataset struct with
%               .sa.targets
%   predicted   Nx1 predicted labels (from a classifier)
%
% Returns
%   mx          PxP matrix assuming there are P unique targets.
%               mx(i,j)==c means that the i-th target class was classified
%               as the j-th target class c times.
%   classes     Px1 class labels.
%
% Note:
%
%
% NNO Aug 2013


    if isstruct(targets)
        cosmo_isfield(targets,'sa.targets',true);
        targets=targets.sa.targets;
    end

    if numel(targets) ~= numel(predicted)
        error('size mismatch between targets and predicted: %d ~= %d', ...
                                numel(targets), numel(predicted));
    end

    % allow lack of predictions for some of the samples
    msk=~isnan(predicted);

    targets=targets(msk);
    predicted=predicted(msk);

    classes=unique(targets);
    nclasses=numel(classes);

    confusion_matrix=zeros(nclasses);
    % >@@>
    for k=1:nclasses
        tmsk=targets==classes(k);
        for j=1:nclasses
            confusion_matrix(k,j)=sum(predicted(tmsk)==classes(j));
        end
    end
    % <@@<

