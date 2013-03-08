//Auto-generated by RSP Compiler
//Source: test/features/webapp/searchResult.rsp.html
part of features;

/** Template, searchResult, for rendering the view. */
void searchResult(HttpConnect connect, {criteria}) { //4
  var _cxs = new List<HttpConnect>(), request = connect.request, response = connect.response, _v_;

  if (!connect.isIncluded)
    response.headers.contentType = new ContentType.fromString("""text/html; charset=utf-8""");

  response.addString("""

<html>
  <head>
    <title>Search Result</title>
    <link href="theme.css" rel="stylesheet" type="text/css" />
  </head>
  <body>
    <h1>Search Result</h1>
    <p>Criteria:</p>
    <ul>
      <li>text: """); //#4

  _v_ = criteria.text; //#14
  if (_v_ != null) response.addString("$_v_");

  response.addString("""
</li>
      <li>since: """); //#14

  _v_ = criteria.since; //#15
  if (_v_ != null) response.addString("$_v_");

  response.addString("""
</li>
      <li>within: """); //#15

  _v_ = criteria.within; //#16
  if (_v_ != null) response.addString("$_v_");

  response.addString("""
</li>
      <li>hasAttachment: """); //#16

  _v_ = criteria.hasAttachment; //#17
  if (_v_ != null) response.addString("$_v_");

  response.addString("""
</li>
    </ul>
  </body>
</html>
"""); //#17

  connect.close();
}
