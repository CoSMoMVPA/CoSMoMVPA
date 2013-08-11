.. exercise2

Exercise 2: Classification with Naive Bayes classifier
=====================================================

Load a dataset using subject s01's T-statistics for every run
('glm_T_stats_perrun.nii.gz') runs and the VT mask. Slice the datset using your sample
attributes slicer so that there are only two categories: monkeys and mallards.
Then slice the datasdet again into odd and even runs.  Train and test a
naive_bayes_ classifier first training on the even-runs data and testing on the
odds, then train on the odds and test on the evens.

Check your answers here: Solution_2_

What is the accuracy for monkey versus ladybug? Monkey versus lemur?

Do the accuracies change if you use betas ('glm_betas_perrun.nii.gz') instead of
T-stats?

What if you use a different mask?

.. _Solution_2: solution_2.html

.. _naive_bayes: naive_bayes.html

       
