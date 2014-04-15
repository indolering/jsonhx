/*
    haxe JsonRPC
*/
package jsonhx;

import haxe.*;
import haxe.remoting.*;
import promhx.Promise;

typedef Param = {type:String, optional: Bool, name: String};

class JsonRpc implements Dynamic {

    var _seq_id: Int = 0;

    private function normalize_name( method_name : String ) : String {
        var new_name = new StringBuf();

        function issymbol( c: Int ) : Bool {
            if( ('a'.charCodeAt( 0 ) <= c && 'z'.charCodeAt( 0 ) >= c) || c == '_'.charCodeAt( 0 ) )
                return true;

            if( ('A'.charCodeAt( 0 ) <= c && 'Z'.charCodeAt( 0 ) >= c))
                return true;

            if( ('0'.charCodeAt( 0 ) <= c && '9'.charCodeAt( 0 ) >= c))
                return true;

            return false;
        }

        for( i in 0...method_name.length ) {
            if( issymbol( method_name.charCodeAt( i )))
                new_name.add( method_name.charAt( i ));
            else
                new_name.add( '_' );
        }

        return new_name.toString();
    }

    private function method_make( target_url: String, services : Dynamic ) : Void {
        for( name in Reflect.fields( services )) {
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

            var pmax = param_defs.length;
            var pmin = pmax - optional_cnt;

            var nname = normalize_name( name );
            trace( 'RPC method "$name" ($nname)' );

            Reflect.setField( this, nname, function( params: Array<Dynamic> ) : Promise<Dynamic> {
                if( params == null )
                    params = [];

                if( params.length <= pmax || params.length >= pmin) {
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

    /**
        This either loads a SMD file from an URL, or gets it from a given json string.
    */
    public function new( smd: String ) {
        var d: String;

        if( smd.charAt( 0 ) == '{' )
            d = smd;
        else
            d = Http.requestUrl( smd );

        var j = haxe.Json.parse( d );

        method_make( j.target, j.services );
    }
}
