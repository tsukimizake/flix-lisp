@Test
def testReadAndShow(): Unit \ Assert =
    let r = EvalError.runResult(() -> Reader.read("(+ 1 (* 2 3)) 'foo #t \"hi\" ; comment\n42"));
    let shown = match r {
        case Ok(vs) => List.joinWith(Value.show, " | ", vs)
        case Err(m) => "ERR:${m}"
    };
    Assert.assertEq(expected = "(+ 1 (* 2 3)) | (quote foo) | #t | \"hi\" | 42", shown)
