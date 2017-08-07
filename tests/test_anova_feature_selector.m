function test_suite=test_anova_feature_selector
% tests for cosmo_anova_feature_selector
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    initTestSuite;

function test_anova_feature_selector_basics
    ds=cosmo_synthetic_dataset();

    aeq=@(arg,res)assertEqual(cosmo_anova_feature_selector(ds,arg),res);
    aeq(.1,2);
    aeq(.45,[2 4 5]);
    aeq(.99,[2 4 5 3 1 6]);
    aeq(1,2);
    aeq(3,[2 4 5]);
    aeq(6,[2 4 5 3 1 6]);

    aet=@(arg)assertExceptionThrown(@()...
                    cosmo_anova_feature_selector(ds,arg),'');

    aet(1.5);
    aet(7);

    ds.samples(:,[2 4 5])=NaN;
    assertEqual(cosmo_anova_feature_selector(ds,3),[3 1 6])
    assertExceptionThrown(@()cosmo_anova_feature_selector(ds,4),'');
