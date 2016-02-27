function test_suite=test_check_dataset()
% tests for cosmo_check_dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_check_dataset_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                                cosmo_check_dataset(varargin{:}),'');
    aeq=@(x,varargin)assertEqual(x,cosmo_check_dataset(varargin{:}));
    % error on empty inputs
    aet([])
    aet(struct);

    % fine with samples
    aeq(true,struct('samples',zeros(2)));
    aet(struct('illegal',zeros(2),'samples',zeros(2)));

    % silence error
    aeq(false,struct('illegal',zeros(2)),false);

    % only accept fmri
    ds=cosmo_synthetic_dataset('type','fmri');
    aeq(true,ds);
    aeq(true,ds,'fmri');
    aet(ds,'meeg');
    aet(ds,'surface');

    % wrong size
    ds_c=ds;
    ds_c.sa.chunks=[2;3];
    aet(ds_c);

    % non-numeric chunks
    ds_c=ds;
    ds_c.sa.chunks={'a','b','c','a','b','c'}';
    aet(ds_c);

    % non-numeric targets
    ds_c=ds;
    ds_c.sa.targets={'a','b','c','a','b','c'}';
    aet(ds_c);

    % destroy fmri info
    ds_c=ds;
    ds_c.a=rmfield(ds_c,'a');
    aeq(true,ds_c); % not for fmri
    aet(ds_c,'fmri');

    % illegal dimension value
    ds=cosmo_synthetic_dataset('type','meeg');
    ds_c=ds;
    ds_c.a.fdim.values{1}=ds_c.a.fdim.values{1}(1:2);
    aet(ds_c);

    % check meeg
    aeq(true,ds);
    aeq(true,ds,'meeg');
    aet(ds,'fmri');
    aet(ds,'surface');

    % illegal indices
    ds_c=ds;
    ds_c.fa.chan=ds_c.fa.chan+6;
    aet(ds_c);

    % surface
    ds=cosmo_synthetic_dataset('type','surface');
    aeq(true,ds);
    aeq(true,ds,'surface');
    aet(ds,'fmri');
    aet(ds,'meeg');

    % unsupported type
    aet(ds,'illegal');

    % legacy
    ds_c=ds;
    ds_c.a.dim=ds.a.fdim;

    aet(ds_c);

    % non-2D samples
    ds_c=ds;
    ds_c.samples=zeros([6,6,2]);
    aet(ds_c)

    % empty attributes
    ds_c=ds;
    ds_c.sa=struct();
    aeq(true,ds_c);

    % non-2D attributes
    ds_c.sa.foo=zeros([6,6,2]);
    aet(ds_c);

    % transposed size
    ds_c=ds;
    ds_c.sa.targets=ds_c.sa.targets';
    aet(ds_c);

    % missing values
    ds_c=ds;
    ds_c.a.fdim=rmfield(ds_c.a.fdim,'values');
    aet(ds_c);

    % non-cell .fdim.values
    ds_c=ds;
    ds_c.a.fdim.values=1;
    aet(ds_c);

    % non-cell .fdim.labels
    ds_c=ds;
    ds_c.a.fdim.labels=1;
    aet(ds_c);

    % different size for labels and values
    ds_c=ds;
    ds_c.a.fdim.values{end+1}=1;
    aet(ds_c);

    % missing .fa
    ds_c=ds;
    ds_c.fa=rmfield(ds_c.fa,'node_indices');
    aet(ds_c);

    % empty .fa is ok
    ds_c=ds;
    ds_c.fa.node_indices=[];
    aeq(true,ds_c);

    % illegal indices
    ds_c=ds;
    ds_c.fa.node_indices=ds_c.fa.node_indices-1;
    aet(ds_c);
    ds_c.fa.node_indices=ds_c.fa.node_indices+2;
    aet(ds_c);
    ds_c.fa.node_indices(:)=0.5;
    aet(ds_c);

    % missing .fa with .fdim present
    ds_c=ds;
    ds_c=rmfield(ds_c,'fa');
    aet(ds_c);








