function test_suite = test_slice
% tests for cosmo_slice
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_slice_arrays
    if cosmo_wtf('is_matlab')
        err_id_invalid_index='MATLAB:badsubscript';
        err_id_out_of_bounds='MATLAB:badsubscript';
    else
        err_id_invalid_index='Octave:invalid-index';
        err_id_out_of_bounds='Octave:index-out-of-bounds';
    end

    % helper functions
    b=@(x)logical(x); % conversion to boolean

    % assert-equal
    aeq=@(args,v) assertEqual(cosmo_slice(args{:}),v);

    % assert-raises with id
    aet_with=@(args,id) assertExceptionThrown(@()cosmo_slice(args{:}),...
                                            id);
    % assert-raises with empty exception
    aet=@(args) aet_with(args,'');

    % support boolean arrays
    xs={[0,1,2;3,4,5],{'a','b','c';'d','ee',''},b([0 1 1; 0 1 0])};
    for k=1:numel(xs)
        x=xs{k};

        aeq({x,1},x(1,:))
        aeq({x,2},x(2,:))
        aeq({x,[1 2]},x)
        aeq({x,[2 1]},x([2 1],:))
        aeq({x,[2 2 1]},x([2 2 1],:))
        aeq({x,[2 2 1]'},x([2 2 1],:))

        aeq({x,1,1},x(1,:))
        aeq({x,2,1},x(2,:))
        aeq({x,[1 2],1},x)
        aeq({x,[2 1],1},x([2 1],:))
        aeq({x,[2 2 1],1},x([2 2 1],:))
        aeq({x,[2 2 1]',1},x([2 2 1],:))

        aeq({x,1,2},x(:,1))
        aeq({x,2,2},x(:,2))
        aeq({x,3,2},x(:,3))
        aeq({x,[1 3],2},x(:,[1 3]))
        aeq({x,[3 1],2},x(:,[3 1]))
        aeq({x,[3 1 1],2},x(:,[3 1 1]))
        aeq({x,[3 1 1]',2},x(:,[3 1 1]))


        % boolean slicing
        aeq({x,b([0 1]),1},x(b([0 1]),:))
        aeq({x,b([0 1 0]),2},x(:,b([0 1 0])))

        aet({x,b([0]),1})
        aet({x,b([0 1]),2})
        aet({x,b([0 1 0]),1})
        aet({x,b([0 1 0 0]),2})

        % indices out of bounds
        aet_with({x,0},err_id_invalid_index)
        aet_with({x,3},err_id_out_of_bounds)
        aet_with({x,0,1},err_id_invalid_index)
        aet_with({x,3,1},err_id_out_of_bounds)
        aet_with({x,0,2},err_id_invalid_index)
        aet_with({x,4,2},err_id_out_of_bounds)

        % no support for 3D arrays
        x=repmat(x,[1 1 2]);
        aet({x,1})
        aet({x,1})
        aet({x,1,1})
        aet({x,1,1})
        aet({x,1,2})
        aet({x,1,2})

    end

function test_slice_datasets()
    % (assumes that slicing of arrays works properly)


    if cosmo_wtf('is_matlab')
        err_id_out_of_bounds='MATLAB:badsubscript';
    else
        err_id_out_of_bounds='Octave:index-out-of-bounds';
    end

    ds=cosmo_synthetic_dataset('size','normal');

    % index- and mask-based slicing
    rand_=@(n)rand(n,1);
    ridx=@(n) ceil(rand_(n*2)*n);
    bmsk=@(n) rand_(n)>.5;

    % helper function
    aet=@(a,b,exc)assertExceptionThrown(@()cosmo_slice(ds,a,b),exc);

    % f generates the indices or boolean values
    % dim is the dimension
    % oob means whether to generate thinks going out of bounds
    param2slice_arg=@(f,dim,oob)f(size(ds.samples,dim)*(1+oob));

    params=cosmo_cartprod({{ridx,bmsk},{1,2},{true,false}});

    attr_labels={'sa','fa'};
    for k=1:size(params,1)
        param=params(k,:);
        slice_arg=param2slice_arg(param{:});
        slice_dim=param{2};
        oob=param{3};

        % slice ds
        if oob
            if isnumeric(slice_arg)
                exc=err_id_out_of_bounds;
            else
                exc='';
            end
            aet(slice_arg, slice_dim, exc);
            continue;
        end

        d=cosmo_slice(ds,slice_arg,slice_dim);

        % samples should match
        assertEqual(d.samples,cosmo_slice(ds.samples,slice_arg,slice_dim));

        % dataset attribues should match
        assertEqual(d.a, ds.a);

        % test .sa and .fa
        for dim=1:numel(attr_labels);
            attr_label=attr_labels{dim};
            assertEqual(fieldnames(d.(attr_label)), ...
                            fieldnames(ds.(attr_label)));

            labels=fieldnames(ds.(attr_label));
            for m=1:numel(labels)
                label=labels{m};
                v=ds.(attr_label).(label);
                w=d.(attr_label).(label);

                if slice_dim==dim
                    % assumes slicing array works fine
                    v=cosmo_slice(v, slice_arg, slice_dim);
                end

                assertEqual(v,w);
            end

            % check slicing of structs
            if slice_dim==dim
                v=ds.(attr_label);
                w=d.(attr_label);
                assertEqual(cosmo_slice(v,slice_arg,dim,'struct'),w);
            end

        end
    end

function test_slice_sa
    helper_test_dataset_slice(1);

function test_slice_fa
    helper_test_dataset_slice(2);

function helper_test_dataset_slice(dim)
    % dataset_slice_{fa,sa} are deprecated, so shows a warning
    warning_state=cosmo_warning();
    warning_state_resetter=onCleanup(@()cosmo_warning(warning_state));
    empty_state=warning_state;
    empty_state.show_warnings={};

    ds=cosmo_synthetic_dataset();

    % select half of samples or features
    sz=size(ds);
    n=sz(dim);
    rp=randperm(n);
    rp=rp(1:round(n/2));

    % set selected result
    expected_result=cosmo_slice(ds,rp,dim);

    % set warning to empty
    cosmo_warning(empty_state);
    cosmo_warning('off');

    % slice dataset
    if dim==1
        result=cosmo_dataset_slice_sa(ds,rp);
    else
        result=cosmo_dataset_slice_fa(ds,rp);
    end

    % compare with expected result
    assertEqual(expected_result,result);

    % warning must have been shown
    w=cosmo_warning();
    assert(~isempty(w.shown_warnings));
    assert(iscellstr(w.shown_warnings));



function test_slice_datasets_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_slice(varargin{:}),'');

    % struct must have field .samples
    aet(struct,1);

    % cannot have function handle as first input
    aet(@abs,1);

    % slicing a struct with size mismatch gives an error
    ds=struct();
    ds.foo=[1 2];
    ds.bar=[1;2];
    aet(ds,1,1,'struct');
    aet(ds,1,2,'struct');

    % dim must be 1 or 2
    aet(zeros(2),1,3);
    aet(zeros(2),1,'foo');
    aet(zeros(2),1,[1 2]);
    aet(zeros(2),1,[1 1]);

    % selector must be a vector
    aet(zeros(2),ones(2),1);
    aet(zeros(2),ones(2),2);
