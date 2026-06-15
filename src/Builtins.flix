///
/// 組み込み関数と初期グローバル環境。
/// 組み込みは名前(`Value.Builtin(name)`)で表し、適用時に `apply` でディスパッチする。
///
mod Builtins {

    use Sys.Console.Console

    /// すべての組み込みを `name -> Builtin(name)` で束縛した初期環境。
    pub def initialEnv(): Map[String, Value] =
        List.foldLeft((m, n) -> Map.insert(n, Value.Builtin(n), m), Map.empty(), names())

    def names(): List[String] =
        "+" :: "-" :: "*" :: "/" ::
        "=" :: "<" :: ">" :: "<=" :: ">=" ::
        "car" :: "cdr" :: "cons" :: "list" :: "null?" :: "not" ::
        "print" :: "println" :: Nil

    pub def apply(name: String, args: List[Value]): Value \ {EvalError, Console} =
        match name {
            case "+"  => Value.Num(List.foldLeft((acc, v) -> acc + asNum(v), 0i64, args))
            case "*"  => Value.Num(List.foldLeft((acc, v) -> acc * asNum(v), 1i64, args))
            case "-"  => arithSub(args)
            case "/"  => arithDiv(args)
            case "="  => cmp("=", args, (a, b) -> a == b)
            case "<"  => cmp("<", args, (a, b) -> a < b)
            case ">"  => cmp(">", args, (a, b) -> a > b)
            case "<=" => cmp("<=", args, (a, b) -> a <= b)
            case ">=" => cmp(">=", args, (a, b) -> a >= b)
            case "car"   => match args {
                case Value.Lst(x :: _) :: Nil => x
                case _                        => EvalError.raise("car expects a non-empty list")
            }
            case "cdr"   => match args {
                case Value.Lst(_ :: xs) :: Nil => Value.Lst(xs)
                case _                         => EvalError.raise("cdr expects a non-empty list")
            }
            case "cons"  => match args {
                case x :: Value.Lst(xs) :: Nil => Value.Lst(x :: xs)
                case _                         => EvalError.raise("cons expects an element and a list")
            }
            case "list"  => Value.Lst(args)
            case "null?" => match args {
                case Value.Lst(Nil) :: Nil => Value.Bool(true)
                case _ :: Nil              => Value.Bool(false)
                case _                     => EvalError.raise("null? expects 1 argument")
            }
            case "not"   => match args {
                case v :: Nil => Value.Bool(not Value.isTruthy(v))
                case _        => EvalError.raise("not expects 1 argument")
            }
            case "print"   => doPrint(args, false)
            case "println" => doPrint(args, true)
            case _ => EvalError.raise("unknown builtin: ${name}")
        }

    def asNum(v: Value): Int64 \ EvalError = match v {
        case Value.Num(n) => n
        case _            => EvalError.raise("expected a number, got ${Value.show(v)}")
    }

    def arithSub(args: List[Value]): Value \ EvalError = match args {
        case Nil       => EvalError.raise("- expects at least 1 argument")
        case v :: Nil  => Value.Num(0i64 - asNum(v))
        case v :: rest => Value.Num(List.foldLeft((acc, x) -> acc - asNum(x), asNum(v), rest))
    }

    def arithDiv(args: List[Value]): Value \ EvalError = match args {
        case a :: b :: rest =>
            let step = (acc, x) -> {
                let d = asNum(x);
                if (d == 0i64) EvalError.raise("division by zero") else acc / d
            };
            Value.Num(List.foldLeft(step, asNum(a), b :: rest))
        case _ => EvalError.raise("/ expects at least 2 arguments")
    }

    def cmp(op: String, args: List[Value], f: (Int64, Int64) -> Bool): Value \ EvalError = match args {
        case a :: b :: Nil => Value.Bool(f(asNum(a), asNum(b)))
        case _             => EvalError.raise("${op} expects 2 arguments")
    }

    def doPrint(args: List[Value], newline: Bool): Value \ {EvalError, Console} = match args {
        case v :: Nil =>
            let s = match v {
                case Value.Str(t) => t
                case _            => Value.show(v)
            };
            if (newline) Console.println(s) else Console.print(s);
            Value.Lst(Nil)
        case _ => EvalError.raise("print expects 1 argument")
    }

}
