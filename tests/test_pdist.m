function test_suite = test_pdist
    initTestSuite;


function test_pdist_()
    data=[1 4 3; 2 2 3; 4 2 0;0 1 1];

    avae=@(x,y)assertVectorsAlmostEqual(x,y,'relative',1e-4);

    d_eucl=[2.2361  4.6904  3.7417  3.6056  3.0000  4.2426];
    d_corr=[0.8110  1.6547  0.0551  1.8660  0.5000  1.8660];

    avae(cosmo_pdist(data),d_eucl);
    avae(cosmo_pdist(data,'euclidean'),d_eucl);
    avae(cosmo_pdist(data,'correlation'),d_corr);

    has_pdist=cosmo_check_external('@stats',false);
    if has_pdist
        avae(pdist(data),d_eucl);
        avae(pdist(data,'euclidean'),d_eucl);
        avae(pdist(data,'correlation'),d_corr);
        avae(pdist(data,'cosine'),cosmo_pdist(data,'cosine'))
    end