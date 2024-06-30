lib:
let
  inherit (builtins) head length listToAttrs match readFile;
  inherit (lib) concatLists concatStrings escapeRegex findFirst fix foldl' last
    nameValuePair;

  comb = {
    any = parsers: str: findFirst
      (v: ! v ? error)
      { error = "failed to match any parser"; }
      (map (p: p str) parsers);

    apply = f: parser: str:
      let v = parser str; in
      if v ? error then v else
        assert v ? value;
        v // { value = f v.value; };

    quiet = parser: str:
      let v = parser str; in
      if v ? error then v else
      { inherit (v) rest; };

    seq = parsers: str: foldl'
      (a: p:
        if a ? error then a else
        let v = p a.rest; in if v ? error then v else {
          value = a.value ++ (if v ? value then [ v.value ] else [ ]);
          rest = v.rest;
        })
      { value = [ ]; rest = str; }
      parsers;

    seq1 = parsers: str:
      comb.apply (v: assert length v == 1; head v) (comb.seq parsers) str;

    maybe = parser: str:
      let v = parser str; in
      if ! v ? error then v else { rest = str; };

    many = parser: fix (self: str:
      let v = parser str; in
      if v ? error then { value = [ ]; rest = str; }
      else
        let next = self v.rest; in {
          value = (if v ? value then [ v.value ] else [ ]) ++ next.value;
          inherit (next) rest;
        });
  };

  parseRegex = rx: type: str:
    let
      m = match "${rx}(.*)" str;
      len = length m;
    in
    if m == null
    then { error = "failed to match ${type}"; }
    else if len == 1 then { rest = last m; }
    else { value = head m; rest = last m; };

  parseStr = s: parseRegex (escapeRegex s) "`${s}`";

  parseStrRep = s: rep: str:
    let v = parseStr s str; in
    if v ? error then v else (v // { value = rep; });

  parseEnd = str:
    if str == ""
    then { rest = ""; }
    else { error = "failed to match end of string"; };

  parseWhitespace = comb.quiet (comb.many (comb.any [
    (parseStr " ")
    (parseStr "\n")
    (parseRegex "//[^\n]*\n" "comment")
  ]));

  parseZonObj = comb.any [
    parseZonStruct
    parseZonTuple
    parseZonStr
  ];

  parseZonAnonStructLitOf = parser: comb.apply concatLists (comb.seq [
    (parseStr ".{")
    (comb.many (comb.seq1 [
      parseWhitespace
      parser
      parseWhitespace
      (parseStr ",")
    ]))
    (comb.maybe (comb.seq [
      parseWhitespace
      parser
    ]))
    parseWhitespace
    (parseStr "}")
  ]);

  parseZonTuple = parseZonAnonStructLitOf parseZonObj;

  parseZonIdent = parseRegex "([a-zA-Z_][a-zA-Z0-9_]*)" "identifier";

  parseZonStructField = comb.apply (v: nameValuePair (head v) (last v))
    (comb.seq [
      (parseStr ".")
      parseZonIdent
      parseWhitespace
      (parseStr "=")
      parseWhitespace
      parseZonObj
    ]);

  parseZonStruct = comb.apply listToAttrs
    (parseZonAnonStructLitOf parseZonStructField);

  parseEscapeSeq = comb.seq1 [
    (parseRegex "\\\\" "backslash")
    (comb.any [
      (parseStrRep "\\" "\\")
      (parseStrRep "n" "\n")
      (parseStrRep "r" "\r")
      (parseStrRep "t" "\t")
      (parseStrRep "'" "'")
      (parseStrRep "\"" "\"")
      (parseStrRep "x" (throw "unhandled escape sequence"))
      (parseStrRep "u" (throw "unhandled escape sequence"))
    ])
  ];

  parseZonStr = comb.apply concatStrings (comb.seq1 [
    (parseStr "\"")
    (comb.many (comb.any [
      (parseRegex "([^\"\n\\])" "string char")
      parseEscapeSeq
    ]))
    (parseStr "\"")
  ]);

  parseZon = comb.seq1 [
    parseWhitespace
    parseZonObj
    parseWhitespace
    parseEnd
  ];
in
path:
let
  v = parseZon (readFile path);
in
if ! v ? error then v.value else throw "failed to parse ${path}"
