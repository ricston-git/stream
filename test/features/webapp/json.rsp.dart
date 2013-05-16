//Auto-generated by RSP Compiler
//Source: test/features/json.rsp.html
part of features;

/** Template, json, for rendering the view. */
Future json(HttpConnect connect) { //#2
  var _t0_, _cs_ = new List<HttpConnect>(),
  request = connect.request, response = connect.response;

  if (!connect.isIncluded)
    response.headers.contentType = ContentType.parse("""text/html; charset=utf-8""");
var map = {
  "first": [123, "abc"],
  "second": true
};

  response.write("""

<html>
  <head>
    <title>Test of Json</title>
  </head>
  <body>
"""); //#7

  _t0_ = RSP.json([map, "another"]);
  response.write("<script>foo = $_t0_;</script>\n");

  response.write("""
    <div id="show"></div>
    <script>
var tests = ["foo[1]", "foo[0].first[0]", "foo[0].second"];
var out = "";
for (var i = 0; i < tests.length; ++i)
  out += tests[i] + ": " + eval(tests[i]) + "<br/>";
document.getElementById("show").innerHTML = out;
    </script>
  </body>
</html>
"""); //#14

  return RSP.nnf();
}
