///
/// 評価器。
///
/// 環境を「ローカル(レキシカル)」と「グローバル(トップレベル)」の2つに分ける。
/// クロージャはローカル環境だけを捕捉し、自由変数はローカル→グローバルの順に探す。
/// グローバルは呼び出し時点の最新版を渡すため、`define` で後から束縛した関数を
/// 参照する再帰・相互再帰が、可変状態なしで成立する。
///
mod Eval {

    use Sys.Console.Console

    /// トップレベルのフォーム列を順に評価し、各結果とグローバル環境の更新を畳み込む。
    pub def runForms(global: Map[String, Value], forms: List[Value]): (List[Value], Map[String, Value]) \ {EvalError, Console} =
        match forms {
            case Nil => (Nil, global)
            case f :: fs =>
                let (v, g1) = evalTop(global, f);
                let (vs, g2) = runForms(g1, fs);
                (v :: vs, g2)
        }

    /// トップレベル評価。`define` のみグローバル環境を更新する。
    pub def evalTop(global: Map[String, Value], expr: Value): (Value, Map[String, Value]) \ {EvalError, Console} =
        match expr {
            case Value.Lst(Value.Sym("define") :: rest) => evalDefine(global, rest)
            case _                                       => (eval(Map.empty(), global, expr), global)
        }

    def evalDefine(global: Map[String, Value], rest: List[Value]): (Value, Map[String, Value]) \ {EvalError, Console} =
        match rest {
            case Value.Sym(name) :: valExpr :: Nil =>
                let v = eval(Map.empty(), global, valExpr);
                (Value.Sym(name), Map.insert(name, v, global))
            case Value.Lst(Value.Sym(name) :: params) :: body =>
                let fn = Value.Fn(symNames(params), body, Map.empty());
                (Value.Sym(name), Map.insert(name, fn, global))
            case _ => EvalError.raise("malformed define")
        }

    /// 式の評価
    pub def eval(local: Map[String, Value], global: Map[String, Value], expr: Value): Value \ {EvalError, Console} =
        match expr {
            case Value.Sym(s) => lookup(local, global, s)

            case Value.Lst(Value.Sym("quote") :: rest) => match rest {
                case e :: Nil => e
                case _        => EvalError.raise("quote expects exactly 1 argument")
            }
            case Value.Lst(Value.Sym("if") :: rest) => match rest {
                case c :: t :: e :: Nil =>
                    if (Value.isTruthy(eval(local, global, c))) eval(local, global, t) else eval(local, global, e)
                case c :: t :: Nil =>
                    if (Value.isTruthy(eval(local, global, c))) eval(local, global, t) else Value.Lst(Nil)
                case _ => EvalError.raise("if expects 2 or 3 arguments")
            }
            case Value.Lst(Value.Sym("lambda") :: rest) => match rest {
                case params :: body => Value.Fn(paramNames(params), body, local)
                case _              => EvalError.raise("lambda expects parameters and a body")
            }
            case Value.Lst(Value.Sym("begin") :: rest)  => evalBody(local, global, rest)
            case Value.Lst(Value.Sym("define") :: _)    => EvalError.raise("define is only allowed at top level")

            case Value.Lst(Nil)       => EvalError.raise("cannot evaluate empty list '()'")
            case Value.Lst(h :: args) =>
                let fn = eval(local, global, h);
                let argVals = List.map(a -> eval(local, global, a), args);
                apply(global, fn, argVals)

            case _ => expr  // Num/Str/Bool/Fn/Builtin は自己評価
        }

    def apply(global: Map[String, Value], fn: Value, args: List[Value]): Value \ {EvalError, Console} =
        match fn {
            case Value.Fn(params, body, captured) =>
                if (List.length(params) != List.length(args))
                    EvalError.raise("arity mismatch: expected ${List.length(params)}, got ${List.length(args)}")
                else
                    let local = List.foldLeft((m, pa) -> { let (p, a) = pa; Map.insert(p, a, m) }, captured, List.zip(params, args));
                    evalBody(local, global, body)
            case Value.Builtin(name) => Builtins.apply(name, args)
            case _                   => EvalError.raise("not a function: ${Value.show(fn)}")
        }

    def evalBody(local: Map[String, Value], global: Map[String, Value], body: List[Value]): Value \ {EvalError, Console} =
        match body {
            case Nil      => EvalError.raise("empty body")
            case e :: Nil => eval(local, global, e)
            case e :: es  =>
                let _ = eval(local, global, e);
                evalBody(local, global, es)
        }

    def lookup(local: Map[String, Value], global: Map[String, Value], s: String): Value \ EvalError =
        match Map.get(s, local) {
            case Some(v) => v
            case None    => match Map.get(s, global) {
                case Some(v) => v
                case None    => EvalError.raise("unbound symbol: ${s}")
            }
        }

    def paramNames(v: Value): List[String] \ EvalError = match v {
        case Value.Lst(xs) => symNames(xs)
        case _             => EvalError.raise("lambda parameters must be a list")
    }

    def symNames(vs: List[Value]): List[String] \ EvalError =
        List.map(x -> match x {
            case Value.Sym(s) => s
            case _            => EvalError.raise("parameter must be a symbol, got ${Value.show(x)}")
        }, vs)

}
