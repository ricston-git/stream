//Auto-generated by RSP Compiler
//Source: test/syntax/syntax.rsp.html
library syntax;

import "dart:io";
import "package:stream/stream.dart";

/** Template, syntax, for rendering the view. */
void syntax(HttpConnect connect, {foo, bool c:false}) { //9
  final request = connect.request, response = connect.response,
    output = response.outputStream;
  var _v_;
  response.headers.contentType = new ContentType.fromString("""${foo.contentType}""");

  response.headers.add("age", """129"""); //#9

  response.headers.add("accept-ranges", foo.acceptRanges); //#9

  output.writeString("""
<!DOCTYPE html>
<html>
  <head>
    <title>"""); //#10

  _v_ = "$foo.name [${foo.title}]"; //#13
  if (_v_ != null) output.writeString("$_v_");

  //#13
  output.writeString("""
</title>
  </head>
  <body>
    <p>This is a test with """);
  output.writeString('"""');
  output.writeString("""
.
    <p>Another expresion: """);

  _v_ = foo.description; //#17
  if (_v_ != null) output.writeString("$_v_");

  output.writeString("""

    <p>An empty expression: """); //#17

  output.writeString("""

    <p>This is not a tag: [foo ], [another and [/none].
    <ul>
"""); //#19

  for (var user in foo.friends) { //#22

    output.writeString("""      <li>"""); //#23

    _v_ = user.name; //#23
    if (_v_ != null) output.writeString("$_v_");

    output.writeString("""

"""); //#23

    if (user.isCustomer) { //#24

      output.writeString("""
      <i>!important!</i>
"""); //#25
    } //if

    while (user.hasMore()) { //#27

      output.writeString("""        """); //#28

      _v_ = user.showMore(); //#28
      if (_v_ != null) output.writeString("$_v_");

      output.writeString("""

"""); //#28
    } //while

    output.writeString("""
      </li>
"""); //#30
  } //for

  output.writeString("""
    </ul>

"""); //#32

  for (var fruit in ["apple", "orange"]) { //#34
  } //for

  output.writeString("""

"""); //#36

  if (foo.isCustomer) { //#37

    output.writeString("""
      *Custmer*
"""); //#38

  } else if (c) { //#39

    connect.forward("""/x/y/z"""); //#40
    return;

  } else if (foo.isEmployee) { //#41

    output.writeString("""
      *Employee*
"""); //#42

    syntax(connect, c: true, foo: """abc"""); //#43
    return;

  } else { //#44

    output.writeString("""
      *Unknown* [/if] 
"""); //#45
  } //if

  output.writeString("""
  </body>
</html>


"""); //#47

  connect.close();
}
