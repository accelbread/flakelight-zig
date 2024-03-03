lib:
let
  inherit (builtins) deepSeq head length listToAttrs match readFile
    replaceStrings tail tryEval;
  inherit (lib) findFirst fix foldl' last nameValuePair;

  comb = {
    any = parsers: str: findFirst
      (v: (tryEval (deepSeq v v)).success)
      (throw "failed to match any parser")
      (map (p: p str) parsers);

    apply = f: parser: str:
      let v = parser str; in
      assert v ? value;
      v // { value = f v.value; };

    seq = parsers: str:
      let
        ret = foldl'
          (a: p:
            let v = p a.rest; in {
              value = a.value ++ (if v ? value then [ v.value ] else [ ]);
              rest = v.rest;
            })
          { value = [ ]; rest = str; }
          parsers;
      in
      if ret.value == [ ]
      then { inherit (ret) rest; }
      else ret;

    seq1 = parsers: str:
      comb.apply (v: assert length v == 1; head v) (comb.seq parsers) str;

    maybe = parser: str:
      let v = parser str; in
      if (tryEval (deepSeq v v)).success
      then v
      else { rest = str; };

    many = parser: fix (self: str:
      let v = parser str; in
      if (tryEval (deepSeq v v)).success
      then
        let next = self v.rest; in {
          value = (if v ? value then [ v.value ] else [ ]) ++ next.value;
          inherit (next) rest;
        }
      else { value = [ ]; rest = str; });
  };

  parseRegex = rx: type: str:
    let
      m = match "${rx}(.*)" str;
      len = length m;
    in
    if m == null
    then throw "failed to match ${type}"
    else if len == 1 then { rest = last m; }
    else { value = head m; rest = last m; };

  parseEnd = str:
    if str == ""
    then { rest = ""; }
    else throw "failed to match end of string";

  parseWhitespace = parseRegex "[ \n]*" "whitespace";

  parseZonObj = comb.any [
    parseZonStruct
    parseZonTuple
    parseZonStr
  ];

  parseZonAnonLitOpen = parseRegex "\\.\\{" "open anonymous literal";

  parseZonAnonLitClose = parseRegex "}" "close anonymous literal";

  parseComma = parseRegex "," "comma";

  parseZonAnonStructLitOf = parser: comb.apply (v: head v ++ tail v) (comb.seq [
    parseZonAnonLitOpen
    (comb.many (comb.seq1 [
      parseWhitespace
      parser
      parseWhitespace
      parseComma
    ]))
    (comb.maybe (comb.seq1 [
      parseWhitespace
      parser
    ]))
    parseWhitespace
    parseZonAnonLitClose
  ]);

  parseZonTuple = parseZonAnonStructLitOf parseZonObj;

  parsePeriod = parseRegex "." "period";

  parseZonIdentifier = parseRegex "([a-zA-Z_][a-zA-Z0-9_]*)" "identifier";

  parseEquals = parseRegex "=" "equals";

  mkNVPair = v: nameValuePair (head v) (last v);

  parseZonStructField = comb.apply mkNVPair (comb.seq [
    parsePeriod
    parseZonIdentifier
    parseWhitespace
    parseEquals
    parseWhitespace
    parseZonObj
  ]);

  parseZonStruct = comb.apply listToAttrs
    (parseZonAnonStructLitOf parseZonStructField);

  unescapeZonStr =
    let
      invalid = throw "unhandled escape sequence";
    in
    replaceStrings
      [ "\\n" "\\r" "\\t" "\\\\" "\\'" "\\\"" "\\x" "\\u{" ]
      [ "\n" "\r" "\t" "\\" "'" "\"" invalid invalid ];

  parseZonStr = comb.apply unescapeZonStr
    (parseRegex "\"(([^\"\\\\]|\\\\[^\\\\]|\\\\\\\\)*)\"" "string");

  parseZon = comb.seq1 [
    parseWhitespace
    parseZonObj
    parseWhitespace
    parseEnd
  ];

  fromZon = str: (parseZon str).value;
in
path:
let
  val = fromZon (readFile path);
  result = tryEval (deepSeq val val);
in
if result.success then val
else throw "failed to parse ${path}"
