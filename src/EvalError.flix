///
/// 評価・パース中のエラーを表す代数的効果。
/// `raise` の戻り値は `Void`(無人型)なので、呼び出すと継続は再開されず計算が打ち切られる。
///
eff EvalError {
    def raise(msg: String): Void
}

mod EvalError {

    ///
    /// `f` の `EvalError` 効果を処理し、結果を `Result` に変換する。
    /// 正常終了なら `Ok(v)`、`raise(msg)` が呼ばれたら `Err(msg)` を返す。
    /// ハンドラは継続 `_k` を捨てるため、`raise` 後の計算は実行されない(abortハンドラ)。
    ///
    pub def runResult(f: Unit -> a \ ef): Result[String, a] \ (ef - EvalError) =
        run {
            Ok(f())
        } with handler EvalError {
            def raise(msg, _k) = Err(msg)
        }

}
