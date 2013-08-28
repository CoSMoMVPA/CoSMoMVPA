function confusion_matrix=cosmo_confusion_matrix(targets, predicted)
% Returns a confusion matrix
%
% mx=cosmo_confusion_matrix(targets, predicted)
% 
% Inputs:           
%   targets     Nx1 targets for N samples, or a struct with .sa.targets
%   predicted   Nx1 predicted labels (from a classifier)
% 
% Returns
%   mx          PxP matrix assuming there are P unique targets.
%               mx(i,j)==c means that the i-th target class was classified
%               as the j-th target class c times.
% 
% NNO Aug 2013


if isstruct(targets)
    if isfield(targets,'sa') && isfield(targets.sa, 'targets')
        targets=targets.sa.targets;
    else
        error('cell without .sa.targets?')
    end
end

if numel(targets) ~= numel(predicted)
    error('size mismach: %d ~= %d', numel(targets), numel(predicted));
end

targets=targets(:);
predicted=predicted(:);

nsamples=numel(targets);

classes=unique(targets);
nclasses=numel(classes);

confusion_matrix=zeros(nclasses);
% >>
for k=1:nclasses
    tmsk=targets==classes(k);
    for j=1:nclasses
        confusion_matrix(k,j)=sum(predicted(tmsk)==classes(j));
    end
end
% <<
