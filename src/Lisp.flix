///
/// ソース文字列を評価するための入口(REPL以外・テストから使う)。
///
mod Lisp {

    ///
    /// `src` 内の全フォームを評価し、各フォームの結果のリストを返す。
    /// 途中で `EvalError` が起きたら `Err(msg)` を返す。
    ///
    /// `EvalError`(評価エラー)と `Console`(出力)の2つの効果を、
    /// それぞれ専用ハンドラで処理して純粋な `Result`(+ IO)に落とす。
    ///
    pub def runString(src: String): Result[String, List[Value]] \ IO =
        Sys.Console.runWithIO(() ->
            EvalError.runResult(() -> {
                let forms = Reader.read(src);
                let (vals, _) = Eval.runForms(Builtins.initialEnv(), forms);
                vals
            })
        )

}
