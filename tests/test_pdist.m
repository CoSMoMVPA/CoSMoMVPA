function test_suite = test_pdist
% tests for cosmo_pdist
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_pdist_()
    data=[1 4 3; 2 2 3; 4 2 0;0 1 1];

    avae=@(x,y)assertVectorsAlmostEqual(x,y,'relative',1e-4);

    d_eucl=[2.2361  4.6904  3.7417  3.6056  3.0000  4.2426];
    d_corr=[0.8110  1.6547  0.0551  1.8660  0.5000  1.8660];

    avae(cosmo_pdist(data),d_eucl);
    avae(cosmo_pdist(data,'euclidean'),d_eucl);
    avae(cosmo_pdist(data,'correlation'),d_corr);

    has_matlab_pdist=cosmo_check_external('@stats',false);
    has_octave_pdist=cosmo_wtf('is_octave') && ~isempty(which('pdist'));
    if has_matlab_pdist || has_octave_pdist
        avae(pdist(data),d_eucl);
        avae(pdist(data,'euclidean'),d_eucl);
        avae(pdist(data,'cosine'),cosmo_pdist(data,'cosine'))
    else
        if cosmo_wtf('is_octave')
            desc='Octave:undefined-function';
        else
            desc='MATLAB:UndefinedFunction';
        end
        assertExceptionThrown(@()cosmo_pdist(data,'cosine'),desc);
    end
