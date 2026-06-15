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

mod Value {

    /// Lisp の表記で値を文字列化する。
    pub def show(v: Value): String = match v {
        case Value.Num(n)      => "${n}"
        case Value.Sym(s)      => s
        case Value.Str(s)      => "\"${s}\""
        case Value.Bool(true)  => "#t"
        case Value.Bool(false) => "#f"
        case Value.Lst(xs)     => "(${List.joinWith(show, " ", xs)})"
        case Value.Fn(_, _, _) => "<lambda>"
        case Value.Builtin(nm) => "<builtin:${nm}>"
    }

    /// Scheme 流の真偽判定: `#f` のみ偽、それ以外はすべて真。
    pub def isTruthy(v: Value): Bool = match v {
        case Value.Bool(false) => false
        case _                 => true
    }

}
