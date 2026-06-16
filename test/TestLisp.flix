mod TestLisp {

    /// `src` を評価し、最後のフォームの結果を Lisp 表記で返す。エラーなら "<error>"。
    def last(src: String): String \ IO = match Lisp.runString(src) {
        case Ok(vs)  => match List.last(vs) {
            case Some(v) => Value.show(v)
            case None    => "<empty>"
        }
        case Err(_) => "<error>"
    }

    def isErr(src: String): Bool \ IO = match Lisp.runString(src) {
        case Err(_) => true
        case Ok(_)  => false
    }

    @Test
    def testArith(): Unit \ {Assert, IO} = {
        Assert.assertEq(expected = "6",  last("(+ 1 2 3)"));
        Assert.assertEq(expected = "5",  last("(- 10 3 2)"));
        Assert.assertEq(expected = "24", last("(* 2 3 4)"));
        Assert.assertEq(expected = "2",  last("(/ 20 2 5)"));
        Assert.assertEq(expected = "-5", last("(- 5)"));
        Assert.assertEq(expected = "7",  last("(+ 1 (* 2 3))"))
    }

    @Test
    def testIf(): Unit \ {Assert, IO} = {
        Assert.assertEq(expected = "10", last("(if (< 1 2) 10 20)"));
        Assert.assertEq(expected = "2",  last("(if #f 1 2)"));
        // Scheme 流: 0 は真
        Assert.assertEq(expected = "1",  last("(if 0 1 2)"))
    }

    @Test
    def testDefineAndLambda(): Unit \ {Assert, IO} = {
        Assert.assertEq(expected = "6",  last("(define x 5) (+ x 1)"));
        Assert.assertEq(expected = "16", last("((lambda (x) (* x x)) 4)"))
    }

    @Test
    def testClosure(): Unit \ {Assert, IO} =
        Assert.assertEq(
            expected = "8",
            last("(define (adder n) (lambda (x) (+ x n))) (define add5 (adder 5)) (add5 3)")
        )

    @Test
    def testRecursion(): Unit \ {Assert, IO} = {
        Assert.assertEq(
            expected = "120",
            last("(define (fact n) (if (= n 0) 1 (* n (fact (- n 1))))) (fact 5)")
        );
        // 相互再帰
        Assert.assertEq(
            expected = "#t",
            last("(define (even? n) (if (= n 0) #t (odd? (- n 1)))) (define (odd? n) (if (= n 0) #f (even? (- n 1)))) (even? 10)")
        )
    }

    @Test
    def testLists(): Unit \ {Assert, IO} = {
        Assert.assertEq(expected = "1",       last("(car (list 1 2 3))"));
        Assert.assertEq(expected = "(2 3)",   last("(cdr (list 1 2 3))"));
        Assert.assertEq(expected = "(0 1 2)", last("(cons 0 (list 1 2))"));
        Assert.assertEq(expected = "#t",      last("(null? (list))"));
        Assert.assertEq(expected = "#f",      last("(null? (list 1))"))
    }

    @Test
    def testQuote(): Unit \ {Assert, IO} = {
        Assert.assertEq(expected = "(1 2 3)", last("'(1 2 3)"));
        Assert.assertEq(expected = "foo",     last("'foo"));
        Assert.assertEq(expected = "(a b)",   last("(quote (a b))"))
    }

    @Test
    def testErrors(): Unit \ {Assert, IO} = {
        Assert.assertEq(expected = true, isErr("(+ 1 #t)"));
        Assert.assertEq(expected = true, isErr("(car 5)"));
        Assert.assertEq(expected = true, isErr("nope"));
        Assert.assertEq(expected = true, isErr("(/ 1 0)"));
        Assert.assertEq(expected = true, isErr("("))
    }

    ///
    /// 末尾呼び出し最適化(TCO)の回帰テスト。
    /// Flix の full Tail Call Elimination により、インタプリタの
    /// `eval -> apply -> evalBody -> eval` チェーン(全て末尾位置)が
    /// 自動的に最適化されている。これが壊れたらこのテストが落ちる。
    ///
    @Test
    def testTailCallLoop(): Unit \ {Assert, IO} =
        Assert.assertEq(
            expected = "#t",
            last("(define (loop n) (if (= n 0) #t (loop (- n 1)))) (loop 1000000)")
        )

    /// 末尾再帰でアキュムレータを使う形(末尾位置に関数呼び出し)。
    @Test
    def testTailCallSum(): Unit \ {Assert, IO} =
        Assert.assertEq(
            expected = "500000500000",
            last("(define (sum n acc) (if (= n 0) acc (sum (- n 1) (+ n acc)))) (sum 1000000 0)")
        )

    /// 相互末尾再帰。Flix の full TCE は mutual tail call も最適化する。
    @Test
    def testTailCallMutual(): Unit \ {Assert, IO} =
        Assert.assertEq(
            expected = "#t",
            last("(define (even? n) (if (= n 0) #t (odd? (- n 1)))) (define (odd? n) (if (= n 0) #f (even? (- n 1)))) (even? 1000000)")
        )

}
