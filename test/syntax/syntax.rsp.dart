//Auto-generated by RSP Compiler
//Source: syntax.rsp.html
library syntax_rsp;

import 'dart:async';
import 'dart:io';
import 'package:stream/stream.dart';
import 'dart:collection' show LinkedHashMap;

var someExternal = 123;

/** Template, syntax, for rendering the view. */
Future syntax(HttpConnect connect, {foo, bool c:false}) { //#5
  var _t0_, _cs_ = new List<HttpConnect>();
  HttpRequest request = connect.request;
  HttpResponse response = connect.response;
  if (!Rsp.init(connect, foo.contentType))
    return new Future.value();

  response.headers..add("age", "129")
    ..add("accept-ranges", foo.acceptRanges); //header#5

  response.headers..add("Cache-Control", "no-cache"); //header#6

  response.write("""<!DOCTYPE html>
<html>
  <head>
    <title>"""); //#7

  response.write(Rsp.nnx("$foo.name [${foo.title}]")); //#10


  response.write("""</title>
  </head>
  <body>
    <p>This is a test with ""\" and \\ and ""\\".
    <p>Another expresion: \""""); //#10

  response.write(Rsp.nnx(foo.description)); //#14


  response.write(""""
    <p>An empty expression: """); //#14

  response.write("""

    <p>This is not a tag: [:foo ], [:another and [/none].
    <ul>
"""); //#16

  for (var user in foo.friends) { //for#19

    response.write("""      <li>"""); //#20

    response.write(Rsp.nnx(user.name)); //#20


    response.write("""

"""); //#20

    if (user.isCustomer) { //if#21

      response.write("""      <i>!important!</i>
"""); //#22
    } //if

    while (user.hasMore()) { //while#24

      response.write("""        """); //#25

      response.write(Rsp.nnx(user.showMore())); //#25


      response.write("""

"""); //#25
    } //while

    response.write("""      </li>
"""); //#27
  } //for

  response.write("""    </ul>

"""); //#29

  for (var fruit in ["apple", "orange"]) { //for#31
  } //for

  response.write("""

"""); //#33

  if (foo.isCustomer) { //if#34

    response.write("""      *Custmer*
"""); //#35

  } else if (c) { //else#36

    return connect.forward("/x/y/z"); //forward#37

  } else if (foo.isEmployee) { //else#38

    response.write("""      *Employee*
"""); //#39

    return Rsp.nnf(syntax(connect, c: true, foo: "abc")); //forward#40

  } else { //else#41

    response.write("""      *Unknown* [/if] 
"""); //#42
  } //if

  response.write("""

"""); //#44

  var whatever = new StringBuffer(); _cs_.add(connect); //var#45
  connect = new HttpConnect.stringBuffer(connect, whatever); response = connect.response;

  response.write("""    define a variable
"""); //#46

  for (var fruit in ["apple", "orange"]) { //for#47

    response.write("""        """); //#48

    response.write(Rsp.nnx(fruit)); //#48


    response.write("""

"""); //#48
  } //for

  connect = _cs_.removeLast(); response = connect.response;
  whatever = whatever.toString();

  response.write("""

"""); //#51

  return connect.include("/abc").then((_) { //include#52

    var _0 = new StringBuffer(); _cs_.add(connect); //var#54
    connect = new HttpConnect.stringBuffer(connect, _0); response = connect.response;

    response.write("""      The content for foo
"""); //#55

    connect = _cs_.removeLast(); response = connect.response;

    return Rsp.nnf(syntax(new HttpConnect.chain(connect), c: true, foo: _0.toString())).then((_) { //include#53

      response.write("""

"""); //#58

      if (foo.isMeaningful) { //if#59

        response.write("""      something is meaningful
"""); //#60

        return connect.forward(Rsp.cat("/foo?abc", {'first': "1st", 'second': foo})); //forward#61
      } //if

      response.write(Rsp.script(connect, "/script/foo.dart", true)); //script#63

      response.write("""    <script>
    \$("#j\\q");
    </script>
  </body>
</html>
"""); //#64

      response..write("<script>")..write("foo1")..write("=") //json-js#69
       ..write(Rsp.json(foo.name.length ~/ 2))..writeln('</script>');
      response..write('<script type="text/plain" id="') //json#70
       ..write("foo2")..write('">')
       ..write(Rsp.json(foo.name.length ~/ 2 * "/]".length))..writeln('</script>');

      response.write("""

"""); //#71

      response.write("""

"""); //#73

      return new Future.value();
    }); //end-of-include
  }); //end-of-include
}
