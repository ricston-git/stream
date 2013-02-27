//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, Jan 14, 2013  4:56:56 PM
// Author: tomyeh
part of stream_rspc;

/**
 * The RSP compiler
 */
class Compiler {
  final String sourceName;
  final String source;
  final IOSink destination;
  final Encoding encoding;
  final bool verbose;
  //the closure's name, args
  String _name, _args, _desc, _contentType;
  final List<_TagContext> _tagCtxs = [];
  _TagContext _current;
  //The position, length and _line of the source
  int _pos = 0, _len, _line = 1;
  //Look-ahead tokens
  final List _lookAhead = [];
  final List<_IncInfo> _incs = []; //included
  String _extra = ""; //extra whitespaces

  Compiler(this.source, this.destination, {
      this.sourceName, this.encoding:Encoding.UTF_8, this.verbose: false}) {
    _tagCtxs.add(_current = new _TagContext.root(this, destination));
    _len = source.length;
  }

  ///Compiles the given source into Dart code. Notice: it can be called only once.
  ///To compile the second time, you have to instantiate another [Compiler].
  void compile() {
    _writeln("//Auto-generated by RSP Compiler");
    if (sourceName != null)
      _writeln("//Source: ${sourceName}");

    bool pgFound = false, started = false;
    int prevln = 1;
    for (var token; (token = _nextToken()) != null; prevln = _line) {
      if (token is String) {
        String text = token;
        if (!started) {
          if (text.trim().isEmpty)
            continue; //skip it
          started = true;
          _start(prevln); //use previous line number since it could be multiple lines
        }
        _outText(text, prevln);
      } else if (token is _Expr) {
        if (!started) {
          started = true;
          _start();
        }
        _outExpr();
      } else if (token is PageTag) {
        if (pgFound)
          _error("Only one page tag is allowed", _line);
        if (started)
          _error("The page tag must be in front of any non-empty content", _line);
        pgFound = true;

        push(token);
        token.begin(_current, _tagData());
        token.end(_current);
        pop();
      } else if (token is DartTag) {
        push(token);
        token.begin(_current, _dartData());
        token.end(_current);
        pop();
      } else if (token is Tag) {
        if (!started) {
          started = true;
          _start();
        }

        push(token);
        token.begin(_current, _tagData());
        if (!token.hasClosing) {
          token.end(_current);
          pop();
        }
      } else if (token is _Ending) {
        final _Ending ending = token;
        if (_current.tag == null || _current.tag.name != ending.name)
          _error("Unexpected [/${ending.name}] (no beginning tag found)", _line);
        _current.tag.end(_current);
        pop();
      } else {
        _error("Unknown token, $token", _line);
      }
    }

    if (started) {
      if (_tagCtxs.length > 1) {
        final sb = new StringBuffer();
        for (int i = _tagCtxs.length; --i >= 1;) {
          if (!sb.isEmpty) sb.write(', ');
          sb..write(_tagCtxs[i].tag)..write(' at line ')..write(_tagCtxs[i].line);
        }
        _error("Unclosed tag(s): $sb");
      }
      _writeln("\n$_extra  connect.close();");
      while (!_incs.isEmpty) {
        _extra = _extra.substring(2);
        _writeln("$_extra  ${_incs.removeLast().invocation} //end-of-include");
      }
      _writeln("}");
    }
  }
  void _start([int line]) {
    if (line == null) line = _line;
    if (_name == null) {
      if (sourceName == null || sourceName.isEmpty)
        _error("The page tag with the name attribute is required", line);

      final i = sourceName.lastIndexOf('/') + 1,
        j = sourceName.indexOf('.', i);
      _name = StringUtil.camelize(
        j >= 0 ? sourceName.substring(i, j): sourceName.substring(i));
    }

    if (verbose) _info("Generate $_name from line $line");

    if (_desc == null)
      _desc = "Template, $_name, for rendering the view.";

    final ctypeSpecified = _contentType != null;
    if (!ctypeSpecified && sourceName != null) {
      final i = sourceName.lastIndexOf('.');
      if (i >= 0) {
        final ct = contentTypes[sourceName.substring(i + 1)];
        if (ct != null)
          _contentType = ct.toString();
      }
    }

    _current.indent();
    _write("\n/** $_desc */\nvoid $_name(HttpConnect connect");
    if (_args != null)
      _write(", {$_args}");
    _writeln(") { //$line\n"
      "  final request = connect.request, response = connect.response;\n"
      "  var _v_;");

    if (_contentType != null) {
      if (!ctypeSpecified) //if not specified, it is set only if not included
        _write('  if (!connect.isIncluded)\n  ');
      _writeln('  response.headers.contentType = new ContentType.fromString('
        '${_toEl(_contentType, quotmark:true)});');
    }
  }

  ///Sets the page information.
  void setPage(String name, String description, String args, String contentType, [int line]) {
    _name = name;
    _noEl(name, "the name attribute", line);
    _desc = description;
    _noEl(description, "the description attribute", line);
    _args = args;
    _noEl(args, "the args attribute", line);
    _contentType = contentType;
  }

  ///Include the given URI.
  void include(String uri, [Map attributes, int line]) {
    _checkInclude(line);
    if (attributes != null && !attributes.isEmpty)
      throw new UnsupportedError("Include from URI with attributes"); //TODO: handle other attributes
    if (verbose) _info("Include $uri", line);

    _writeln('\n${_current.pre}connect.include('
      '${_toEl(uri, quotmark:true)}, success: () { //#$line');
    _extra = "  $_extra";
    _incs.add(new _IncInfo("});"));
  }
  ///Include the output of the given renderer
  void includeHandler(String method, [Map args, int line]) {
    _checkInclude(line);
    if (verbose) _info("Include $method", line);

    _writeln("\n${_current.pre}$method(connect.server.connectForInclusion(connect, success: () { //#$line");
    _extra = "  $_extra";

    final sb = new StringBuffer("})");
    if (args != null)
      for (final arg in args.keys)
        sb..write(", ")..write(arg)..write(": ")..write(_toEl(args[arg]));
    sb.write(");");
    _incs.add(new _IncInfo(sb.toString()));
  }
  void _checkInclude(int line) {
    final parent = _current.parent;
    if (parent != null) { //no nested allowed (limitation of async programming)
      final pline = _tagCtxs[_tagCtxs.length - 2].line;
      _error("The include tag must be top-level "
        "(rather than inside ${parent} at line ${pline})."
        "Try to split into multiple files or use an expression in the uri attribute.", line);
    }
  }

  //Tokenizer//
  _nextToken() {
    if (!_lookAhead.isEmpty)
      return _lookAhead.removeLast();

    final sb = new StringBuffer();
    final token = _specialToken(sb);
    if (token is _Ending)
      _skipFollowingSpaces();

    final text = _rmSpacesBeforeTag(sb.toString(), token);
    if (text.isEmpty)
      return token;

    if (token != null)
      _lookAhead.add(token);
    return text;
  }
  _specialToken(StringBuffer sb) {
    while (_pos < _len) {
      final cc = source[_pos];
      if (cc == '[') {
        final j = _pos + 1;
        if (j < _len) {
          final c2 = source[j];
          if (c2 == '=') { //[=exprssion]
            _pos = j + 1;
            return new _Expr();
          } else if (c2 == '/') { //[/ending-tag]
            int k = j + 1;
            if (k < _len && StringUtil.isChar(source[k], lower:true)) {
              int m = _skipId(k);
              final tagnm = source.substring(k, m);
              final tag = tags[tagnm];
              if (tag != null && m < _len && source[m] == ']') { //tag found
                if (!tag.hasClosing)
                  _error("[/$tagnm] not allowed. It doesn't need the ending tag.", _line);
                _pos = m + 1;
                return new _Ending(tagnm);
              }
            }
            //fall through
          } else if (c2 == '!') { //[!-- comment --]
            if (j + 2 < _len && source[j + 1] == '-' && source[j + 2] == '-') {
              _pos = _skipUntil("--]", j + 3) + 3;
              continue;
            }
          } else if (StringUtil.isChar(c2, lower:true)) { //[beginning-tag]
            int k = _skipId(j);
            final tag = tags[source.substring(j, k)];
            if (tag != null) { //tag found
              _pos = k;
              return tag;
            }
            //fall through
          }
        }
      } else if (cc == '\\') { //escape
        final j = _pos + 1;
        if (j < _len && source[j] == '[') {
          sb.write('['); //\[ => [
          _pos += 2;
          continue;
        }
      } else if (cc == '\n') {
        _line++;
      }
      sb.write(cc);
      ++_pos;
    } //for each cc
    return null;
  }
  ///(Optional but for better output) Skips the following whitespaces untile linefeed
  void _skipFollowingSpaces() {
    for (int i = _pos; i < _len; ++i) {
      final cc = source[i];
      if (cc == '\n') {
        ++_line;
        _pos = i + 1; //skip white spaces until and including linefeed
        return;
      }
      if (cc != ' ' && cc != '\t')
        break; //don't skip anything
    }
  }
  ///(Optional but for better output) Removes the whitspaces before the given token,
  ///if it is a tag. Notice: [text] is in front of [token]
  String _rmSpacesBeforeTag(String text, token) {
    if (token is! Tag && token is! _Ending)
      return text;

    for (int i = text.length; --i >= 0;) {
      final cc = text[i];
      if (cc == '\n')
        return text.substring(0, i + 1); //remove tailing spaces (excluding \n)
      if (cc != ' ' && cc != '\t')
        return text; //don't skip anything
    }
    return "";
  }
  ///[bracket]: whether to count '[' and ']'
  int _skipUntil(String until, int from, {bool quotmark: false, bool bracket: false}) {
    final line = _line;
    final nUtil = until.length;
    String sep, first = until[0];
    int nbkt = 0;
    for (; from < _len; ++from) {
      final cc = source[from];
      if (cc == '\n') {
        _line++;
      } else if (sep == null) {
        if (quotmark && (cc == '"' || cc == "'")) {
          sep = cc;
        } else if (nbkt == 0 && cc == first) {
          if (from + nUtil > _len)
            break;
          for (int n = nUtil;;) {
            if (--n < 1) //matched
              return from;

            if (source[from + n] != until[n])
              break;
          }
        } else if (bracket && cc == '[') {
          ++nbkt;
        } else if (bracket && cc == ']') {
          --nbkt;
        }
      } else if (cc == sep) {
        sep = null;
      } else if (cc == '\\' && from + 1 < _len) {
        if (source[++from] == '\n')
          _line++;
      }
    }
    _error("Expect '$until'", line);
  }
  int _skipId(int from) {
    for (; from < _len; ++from) {
      final cc = source[from];
      if (!StringUtil.isChar(cc, lower:true, upper:true))
        break;
    }
    return from;
  }
  String _tagData({skipFollowingSpaces: true}) {
    int k = _skipUntil("]", _pos, quotmark: true, bracket: true);
    final data = source.substring(_pos, k).trim();
    _pos = k + 1;
    if (skipFollowingSpaces)
      _skipFollowingSpaces();
    return data;
  }
  String _dartData() {
    String data = _tagData();
    if (!data.isEmpty)
      _warning("The dart tag has no attribute", _line);
    int k = _skipUntil("[/dart]", _pos);
    data = source.substring(_pos, k).trim();
    _pos = k + 7;
    return data;
  }

  //Utilities//
  void _outText(String text, [int line]) {
    if (line == null) line = _line;
    final pre = _current.pre;
    int i = 0, j;
    while ((j = text.indexOf('"""', i)) >= 0) {
      if (line != null) {
        _writeln("\n$pre//#$line");
        line = null;
      }
      _writeln('$pre${_outTripleQuot(text.substring(i, j))}\n'
        '${pre}response.addString(\'"""\');');
      i = j + 3;
    }
    if (i == 0) {
      _write('\n$pre${_outTripleQuot(text)}');
      if (line != null) _writeln(" //#$line");
    } else {
      _writeln('$pre${_outTripleQuot(text.substring(i))}');
    }
  }
  String _outTripleQuot(String text) {
    //Note: Dart can't handle """" (four quotation marks)
    var cb = text.startsWith('"') || text.indexOf('\n') >= 0 ? '\n': '', ce = "";
    if (text.endsWith('"')) {
      ce = '\\"';
      text = text.substring(0, text.length - 1);
    }
    return 'response.addString("""$cb$text$ce""");';
  }

  void _outExpr() {
    //it doesn't push, so we have to use _line instead of _current.line
    final line = _line; //_tagData might have multiple lines
    final expr = _tagData(skipFollowingSpaces: false); //no skip space for expression
    if (!expr.isEmpty) {
      final pre = _current.pre;
      _writeln('\n${pre}_v_ = $expr; //#${line}\n'
        '${pre}if (_v_ != null) response.addString("\$_v_");');
    }
  }

  void _write(String str) {
    _current.write(str);
  }
  void _writeln([String str]) {
    if (?str) _current.writeln(str);
    else _current.writeln();
  }

  String _toComment(String text) {
    text = text.replaceAll("\n", "\\n");
    return text.length > 30 ? "${text.substring(0, 27)}...": text;
  }
  ///Throws an exception if the value is EL
  void _noEl(String val, String what, [int line]) {
    if (val != null && _isEl(val))
      _error("Expression not allowed in $what", line);
  }
  ///Throws an exception (and stops execution).
  void _error(String message, [int line]) {
    throw new SyntaxException(sourceName, line != null ? line: _current.line, message);
  }
  ///Display an warning.
  void _warning(String message, [int line]) {
    print("$sourceName:${line != null ? line: _current.line}: Warning! $message");
  }
  ///Display a message.
  void _info(String message, [int line]) {
    print("$sourceName:${line != null ? line: _current.line}: $message");
  }

  void push(Tag tag) {
    _tagCtxs.add(_current = new _TagContext.child(_current, tag, _line));
  }
  void pop() {
    final prev = _tagCtxs.removeLast();
    _current = _tagCtxs.last;
  }
}

///Syntax error.
class SyntaxException implements Exception {
  String _msg;
  ///The source name
  final String sourceName;
  ///The line number
  final int line;
  SyntaxException(this.sourceName, this.line, String message) {
    _msg = "$sourceName:$line: $message";
  }
  String get message => _msg;
}

class _TagContext extends TagContext {
  String _pre;

  ///The tag
  Tag tag;
  ///The line number
  final int line;

  _TagContext.root(Compiler compiler, IOSink output)
    : _pre = "", line = 1, super(null, compiler, output);
  _TagContext.child(_TagContext prev, this.tag, this.line)
    : _pre = prev._pre, super(prev.tag, prev.compiler, prev.output);

  String get pre => compiler._extra.isEmpty ? _pre: "${compiler._extra}$_pre";
  String indent() => _pre = "$_pre  ";
  String unindent() => _pre = _pre.isEmpty ? _pre: _pre.substring(2);

  void error(String message, [int line]) {
    compiler._error(message, line);
  }
  void warning(String message, [int line]) {
    compiler._warning(message, line);
  }
  String toString() => "($line: $tag)";
}
class _Expr {
}
class _Ending {
  final String name;
  _Ending(this.name);
}
class _IncInfo {
  ///The statement to generate. If null, it means URI is included (rather than handler)
  final String invocation;
  _IncInfo(this.invocation);
}

///Test if the given value is enclosed with `[= ]`.
bool _isEl(String val) => val.startsWith("[=") && val.endsWith("]");
///Converts the value to a valid Dart statement
///[quotmark] specifies whether to enclose the expression with `"""` if found
String _toEl(String val, {quotmark: false}) {
  var el = _isEl(val) ? val.substring(2, val.length - 1).trim(): null;
  return el == null ? val != null ? '"""$val"""': quotmark ? '""': "null":
    el.isEmpty ? '""': quotmark ? '"""\${$el}"""': el;
}
