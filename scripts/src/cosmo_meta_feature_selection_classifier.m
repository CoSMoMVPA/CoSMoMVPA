function predicted=cosmo_meta_feature_selection_classifier(samples_train, targets_train, samples_test, opt)

classifier=opt.classifier;
feature_selector=opt.feature_selector;
ratio_to_keep=opt.feature_selection_ratio_to_keep;

ds=struct();
ds.samples=samples_train;
ds.sa.targets=targets_train;
feature_idxs=feature_selector(ds, ratio_to_keep);

selected_samples_train=samples_train(:,feature_idxs);
selected_samples_test=samples_test(:,feature_idxs);

predicted=classifier(selected_samples_train, targets_train, selected_samples_test);







