///
/// S式の読み取り(字句解析 + 構文解析)。文字列を `List[Value]` に変換する。
/// パースエラーは `EvalError.raise` で打ち切る。
///
mod Reader {

    enum Token with Eq {
        case LParen
        case RParen
        case Tick          // クォート ' の糖衣
        case Atom(String)  // 数値 / シンボル / #t / #f
        case Str(String)
    }

    /// ソース文字列をトップレベルのフォーム列にする。
    pub def read(src: String): List[Value] \ EvalError =
        parseAll(tokenize(String.toList(src)))

    // --- 字句解析 ---

    def tokenize(cs: List[Char]): List[Token] \ EvalError = match cs {
        case Nil      => Nil
        case c :: rest =>
            if (Char.isWhitespace(c))      tokenize(rest)
            else if (c == '(')             Token.LParen :: tokenize(rest)
            else if (c == ')')             Token.RParen :: tokenize(rest)
            else if (c == '\'')            Token.Tick :: tokenize(rest)
            else if (c == ';')             tokenize(dropLine(rest))
            else if (c == '"') {
                let (s, rest2) = readString(rest, Nil);
                Token.Str(s) :: tokenize(rest2)
            }
            else {
                let (a, rest2) = readAtom(cs, Nil);
                Token.Atom(a) :: tokenize(rest2)
            }
    }

    def isDelim(c: Char): Bool =
        Char.isWhitespace(c) or c == '(' or c == ')' or c == '\'' or c == '"' or c == ';'

    def readAtom(cs: List[Char], acc: List[Char]): (String, List[Char]) = match cs {
        case Nil       => (charsToString(List.reverse(acc)), Nil)
        case c :: rest =>
            if (isDelim(c)) (charsToString(List.reverse(acc)), cs)
            else            readAtom(rest, c :: acc)
    }

    def readString(cs: List[Char], acc: List[Char]): (String, List[Char]) \ EvalError = match cs {
        case Nil               => EvalError.raise("unterminated string literal")
        case '"' :: rest       => (charsToString(List.reverse(acc)), rest)
        case '\\' :: c :: rest => readString(rest, unescape(c) :: acc)
        case c :: rest         => readString(rest, c :: acc)
    }

    def unescape(c: Char): Char = match c {
        case 'n'  => '\n'
        case 't'  => '\t'
        case '"'  => '"'
        case '\\' => '\\'
        case _    => c
    }

    def dropLine(cs: List[Char]): List[Char] = match cs {
        case Nil          => Nil
        case '\n' :: rest => rest
        case _ :: rest    => dropLine(rest)
    }

    def charsToString(cs: List[Char]): String =
        List.foldRight((c, acc) -> "${c}${acc}", "", cs)

    // --- 構文解析 ---

    def parseAll(ts: List[Token]): List[Value] \ EvalError = match ts {
        case Nil => Nil
        case _   =>
            let (v, rest) = parseExpr(ts);
            v :: parseAll(rest)
    }

    def parseExpr(ts: List[Token]): (Value, List[Token]) \ EvalError = match ts {
        case Nil                  => EvalError.raise("unexpected end of input")
        case Token.LParen :: rest => parseList(rest, Nil)
        case Token.RParen :: _    => EvalError.raise("unexpected ')'")
        case Token.Tick :: rest   =>
            let (v, rest2) = parseExpr(rest);
            (Value.Lst(Value.Sym("quote") :: v :: Nil), rest2)
        case Token.Atom(a) :: rest => (atomToValue(a), rest)
        case Token.Str(s) :: rest  => (Value.Str(s), rest)
    }

    def parseList(ts: List[Token], acc: List[Value]): (Value, List[Token]) \ EvalError = match ts {
        case Nil                  => EvalError.raise("missing ')'")
        case Token.RParen :: rest => (Value.Lst(List.reverse(acc)), rest)
        case _                    =>
            let (v, rest) = parseExpr(ts);
            parseList(rest, v :: acc)
    }

    def atomToValue(s: String): Value = match s {
        case "#t" => Value.Bool(true)
        case "#f" => Value.Bool(false)
        case _    => match Int64.fromString(s) {
            case Some(n) => Value.Num(n)
            case None    => Value.Sym(s)
        }
    }

}
