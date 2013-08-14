% Demean the dataset
ds.samples = bsxfun(@minus, ds.samples, mean(ds.samples,1));
