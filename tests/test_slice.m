function test_suite = test_slice
    initTestSuite;


function test_slice_arrays
    
    % helper functions
    b=@(x)logical(x); % conversion to boolean
    
    % assert-equal
    aeq=@(args,v) assertEqual(cosmo_slice(args{:}),v);
    
    % assert-raises
    aet=@(args) assertExceptionThrown(@()cosmo_slice(args{:}),'');
    
    % assert-raises with bad subscript
    aet_bs=@(args) assertExceptionThrown(@()cosmo_slice(args{:}),...
                                            'MATLAB:badsubscript');
    
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
        aet_bs({x,0})
        aet_bs({x,3})
        aet_bs({x,0,1})
        aet_bs({x,3,1})
        aet_bs({x,0,2})
        aet_bs({x,4,2})
        
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
    
    
    ds=generate_test_dataset();
    
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
                exc='MATLAB:badsubscript';
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
    
    