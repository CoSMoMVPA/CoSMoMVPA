function test_suite = test_plot_slices
% tests for plot_slices
%
% only includes testing for exceptions, as we don't use GUI in testing
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_plot_slices_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_plot_slices(varargin{:}),'');
    % empty struct
    aet(struct);

    % dataset with more than one volume
    ds=cosmo_synthetic_dataset();
    assert(size(ds.samples,1)>1);
    aet(ds);

    % 4D array
    aet(rand([3,3,3,3]))

    % 5D array
    aet(rand([2,2,2,2]))

    % MEG dataset
    ds=cosmo_synthetic_dataset('type','meeg','ntargets',1,'nchunks',1);
    assert(size(ds.samples,1)==1);
    aet(ds);