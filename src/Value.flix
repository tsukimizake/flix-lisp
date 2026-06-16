///
/// Lisp の値。コードもデータも同じ `Value` で表す(homoiconic)。
/// `Fn` は仮引数・本体式列・定義時のローカル環境(レキシカルスコープ)を保持する。
/// `Builtin` は組み込み関数を名前で表し、適用時に名前でディスパッチする。
///
enum Value with Eq {
    case Num(Int64)
    case Sym(String)
    case Str(String)
    case Bool(Bool)
    case Lst(List[Value])
    case Fn(List[String], List[Value], Map[String, Value])
    case Builtin(String)
}

///
/// `Formattable` インスタンス。本体は `Value.format` に委譲する。
/// これにより `RichString.join` などの汎用関数で `List[Value]` を扱える。
///
instance Formattable[Value] {
    pub def format(v: Value): RichString = Value.format(v)
}

mod Value {

    ///
    /// Lisp 値を意味的に色付けした `RichString` として整形する。
    /// 端末が ANSI 色をサポートしていれば REPL で着色表示される。
    ///
    pub def format(v: Value): RichString = match v {
        case Value.Num(n)      => RichString.cyan("${n}")
        case Value.Sym(s)      => RichString.fromString(s)
        case Value.Str(s)      => RichString.green("\"${s}\"")
        case Value.Bool(true)  => RichString.magenta("#t")
        case Value.Bool(false) => RichString.magenta("#f")
        case Value.Lst(xs)     =>
            RichString.gray("(") +
            RichString.joinWith(format, RichString.fromString(" "), xs) +
            RichString.gray(")")
        case Value.Fn(_, _, _) => RichString.gray("<lambda>")
        case Value.Builtin(nm) => RichString.gray("<builtin:${nm}>")
    }

    /// Lisp の表記で値を文字列化する(色なしのプレーン文字列)。
    /// テストの assert やエラーメッセージへの埋め込み用。
    pub def show(v: Value): String = RichString.toPlainString(format(v))

    /// Scheme 流の真偽判定: `#f` のみ偽、それ以外はすべて真。
    pub def isTruthy(v: Value): Bool = match v {
        case Value.Bool(false) => false
        case _                 => true
    }

}
