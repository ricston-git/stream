//Auto-generated by RSP Compiler
//Source: test/features/webapp/includerView.rsp.html
part of features;

final infos = {
  "fruits": ["apple", "orange", "lemon"],
  "cars": ["bmw", "audi", "honda"]
};

/** Template, includerView, for rendering the view. */
void includerView(HttpConnect connect) { //8
  final request = connect.request, response = connect.response;
  var _v_;
  if (!connect.isIncluded)
    response.headers.contentType = new ContentType.fromString("""text/html; charset=utf-8""");

  response.addString("""

<html>
  <head>
    <title>Test of Include</title>
    <link href="/theme.css" rel="stylesheet" type="text/css" />
  </head>
  <body>
    <ul>
      <li>You shall see something inside the following two boxes.</li>
    </ul>
    <div style="border: 1px solid blue">
"""); //#8

  connect.include("""/frag.html""", success: () { //#19

    response.addString("""
    </div>
    <div style="border: 1px solid red">
"""); //#20

    fragView(connect.server.connectForInclusion(connect, success: () { //#22

      response.addString("""
    </div>
  </body>
</html>
"""); //#23

      connect.close();
    }), infos: infos); //end-of-include
  }); //end-of-include
}
