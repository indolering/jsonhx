jsonhx
======

Haxe lib to handle JsonRPC, and handling calles async using promhx.


Example
=======

The simple example is like this :

var rpc = new JsonRpc( "http://a_host/my_test_service.smd" );

rpc.status([]).then( funtion( res ) {
    trace( "Result of PRC call is $res" );
});

Please note that the "status" function are dynamicly added to the rpc class, and 
haxe hace not a chance to staticly test any arguments. So any errors related to 
given arguements, are given runtime.
