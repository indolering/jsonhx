/*
    haxe JsonRPC
*/
package jsonprc;

import haxe.*;
import haxe.remoting.*;
import promhx.Promise;

typedef Param = {type:String, optional: Bool, name: String};

class JsonRpc implements Dynamic {

    var _seq_id: Int = 0;

    private function method_make( target_url: String, services : Dynamic ) : Void {
        for( name in Reflect.fields( services    )) {
            var def = Reflect.field( services, name );

            // Read and convert to haxe types
            var optional_cnt = 0;
            var param_defs : Array<Param> = [];
            if( Reflect.hasField( def, "parameters" )) {
                for( pname in Reflect.fields( def.parameters )) {
                    var p = Reflect.field( def.parameters, pname );

                    var par = {
                        type: p.type,
                        optional: false,
                        name: p.name
                    };

                    if( p.optional ) {
                        par.optional = p.optional;
                        optional_cnt++;
                    }
                    param_defs.push( par );
                }
            }

            trace( 'RPC method "$name"' );

            Reflect.setField( this, name, function( params: Array<Dynamic> ) : Promise<Dynamic> {
                if( params == null )
                    params = [];

                if( params.length == param_defs.length ) {
                    var r = new Promise<Dynamic>();

                    var h = new Http( target_url );

                    var body = {
                        id : ++_seq_id,
                        jsonrpc: "2.0",
                        method: name,
                        params: params
                    };

                    h.setPostData( haxe.Json.stringify( body ));

                    h.onData = function( response: String ) {
                        var jres = haxe.Json.parse( response );

                        if( jres.id == _seq_id ) {
                            if( jres.error )
                                r.reject( jres.error );
                            else
                                r.resolve( jres.result );
                        }
                    };

                    h.onError = function( error: String ) {
                        r.reject( error );
                    };

                    h.request( true );
                    return r;
                }

                throw( 'RPC argument mismatch' );
            });
        }
    }

    public function new( smb_url: String ) {
        var d = Http.requestUrl( smb_url );

        var j = haxe.Json.parse( d );

        method_make( j.target, j.services );
    }
}
