//Auto-generated by RSP Compiler
//Source: example/hello-templating/classic.rsp.html
part of hello_templating;

/** Template, classic, for rendering the view. */
Future classic(HttpConnect connect, {header, sidebar, body, footer}) { //#2
  var _t0_, _cs_ = new List<HttpConnect>(),
  request = connect.request, response = connect.response;

  if (!connect.isIncluded)
    response.headers.contentType = ContentType.parse("""text/html; charset=utf-8""");

  response.write("""
<div>
  <div class="header">
    """); //#2

  response.write(RSP.nns(header)); //#4


  response.write("""

  </div>
  <div class="sidebar">
    """); //#4

  response.write(RSP.nns(sidebar)); //#7


  response.write("""

  </div>
  <div class="body">
    """); //#7

  response.write(RSP.nns(body)); //#10


  response.write("""

  </div>
  <div class="footer">
    """); //#10

  response.write(RSP.nns(footer)); //#13


  response.write("""

  </div>
</div>
"""); //#13

  return RSP.nnf();
}
