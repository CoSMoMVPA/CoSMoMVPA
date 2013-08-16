function confusion_matrix=cosmo_confusion_matrix(targets, predicted)

if isstruct(targets)
    if isfield(targets,'sa') && isfield(targets.sa, 'targets')
        targets=targets.sa.targets;
    else
        error('cell without .sa.targets?')
    end
end

if numel(targets) ~= numel(predicted)
    targets
    error('size mismach: %d ~= %d', numel(targets), numel(predicted));
end

targets=targets(:);
predicted=predicted(:);

nsamples=numel(targets);

classes=unique(targets);
nclasses=numel(classes);

confusion_matrix=zeros(nclasses);
for k=1:nclasses
    tmsk=targets==classes(k);
    for j=1:nclasses
        confusion_matrix(k,j)=sum(predicted(tmsk)==classes(j));
    end
end
