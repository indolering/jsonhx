jsonhx
======

Haxe lib to handle JsonRPC, and handling calles async using promhx.

I try to use [this](http://tools.ietf.org/html/draft-zyp-json-schema-04) for the structure of the SMD file.

Example
=======

The simple example is like this :
    import jsonhx.*;

    ...
    
    var rpc = new JsonRpc( "http://a_host/my_test_service.smd" );

    rpc.status([]).then( funtion( res ) {
        trace( "Result of PRC call is $res" );
    });

Please note that the "status" function are dynamically added to the rpc class, and
haxe hace not a chance to staticly test any arguments. So any errors related to
given arguements, are given runtime.

Also note that arguments are given in an array, as we cant create a function and
arguments for this dynamically either.
