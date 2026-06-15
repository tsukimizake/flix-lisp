# flix-lisp

Flix の学習用に書いたミニマルな Lisp 処理系。
代数的データ型・パターンマッチ・再帰に加え、Flix の目玉である**代数的効果(algebraic effects)**を
評価エラー(`EvalError`)と入出力(`Console`)に使っている。

## 使い方

```sh
flix run     # REPL を起動(Ctrl-D で終了)
flix test    # テスト実行
flix build   # ビルドのみ
```

REPL の例:

```
lisp> (define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))
fact
lisp> (fact 10)
3628800
lisp> (define add5 ((lambda (n) (lambda (x) (+ x n))) 5))
add5
lisp> (add5 3)
8
lisp> (car 5)
error: car expects a non-empty list      ← エラーが出てもループは継続
```

## サポートする言語機能

- データ: 整数(Int64)・シンボル・文字列・真偽値(`#t`/`#f`)・リスト
- 特殊形式: `quote`(`'` 糖衣)・`if`・`define`・`lambda`・`begin`
- 組み込み: `+ - * / = < > <= >=`、`car cdr cons list null? not`、`print println`
- レキシカルスコープのクロージャ、トップレベル `define` による(相互)再帰
- 行コメント `;`

## 構成

| ファイル | 役割 |
|----------|------|
| `src/Value.flix`     | 値の代数的データ型 `Value` と表示・真偽判定 |
| `src/EvalError.flix` | 評価エラーを表す効果 `EvalError` とハンドラ |
| `src/Reader.flix`    | S式パーサ(字句解析 + 構文解析) |
| `src/Eval.flix`      | 評価器(特殊形式・適用・環境) |
| `src/Builtins.flix`  | 組み込み関数と初期環境 |
| `src/Lisp.flix`      | 文字列を評価する入口(テスト用) |
| `src/Main.flix`      | REPL |

## Flix の学習ポイント

### 1. 代数的効果でエラーを表す

`EvalError` は戻り値が `Void`(無人型)の効果操作 `raise` を持つ。
`Void` は値を持てないので、`raise` を呼ぶと継続は再開されず計算が打ち切られる。

```flix
eff EvalError {
    def raise(msg: String): Void
}
```

ハンドラ側で継続 `_k` を捨てれば、例外のような「中断」になる:

```flix
run { Ok(f()) } with handler EvalError {
    def raise(msg, _k) = Err(msg)   // 継続を呼ばない = そこで打ち切り
}
```

REPL は行ごとにこのハンドラを掛けるので、エラーが起きてもループ全体は死なない。
`Result` を全関数で引き回す必要がなく、評価器本体は「成功する場合」だけを書ける。

### 2. 効果は型に現れ、合成できる

評価器の型は `Value \ {EvalError, Console}`。エラーと出力という 2 つの効果を持つことが
シグネチャに明示される。`Lisp.runString` は両方をそれぞれのハンドラで処理し、
最終的に `Result[String, List[Value]] \ IO` という純粋(IO のみ)な値に落とす。

### 3. 可変状態なしで再帰を実現

環境を「ローカル(レキシカル)」と「グローバル(トップレベル)」に分け、
クロージャはローカルのみ捕捉する。自由変数はローカル→グローバルの順に解決し、
グローバルは**呼び出し時点の最新版**を渡す。これにより、`define` で後から束縛した
関数を参照する再帰・相互再帰が、`Ref` などの可変状態なしで成立する。
