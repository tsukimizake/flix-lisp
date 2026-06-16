use Sys.Console.Console

///
/// REPL。標準入力を1行ずつ読み、評価して結果を表示する。
/// 行ごとに `EvalError` をハンドルするため、エラーが出てもループは止まらない。
/// 定義(`define`)はグローバル環境に蓄積され、次の入力に引き継がれる。
///
def main(): Unit \ IO =
    Sys.Console.runWithIO(() -> {
        Console.println("flix-lisp REPL — Ctrl-D で終了");
        repl(Builtins.initialEnv())
    })

def repl(global: Map[String, Value]): Unit \ Console =
    Console.print("lisp> ");
    match Console.readln() {
        case None       => Console.println("bye")
        case Some(line) =>
            match EvalError.runResult(() -> Eval.runForms(global, Reader.read(line))) {
                case Ok((vals, newGlobal)) =>
                    List.forEach(v -> Console.println(RichString.toString(Value.format(v))), vals);
                    repl(newGlobal)
                case Err(msg) =>
                    Console.println("error: ${msg}");
                    repl(global)
            }
    }
