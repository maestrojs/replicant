QUnit.specify "namespace", ->
    describe "namespace", ->

        test =
            A: 1
            B:
             one: 1
             two: 2
        test = replicant.create test

        #bone = test["B.one"]
        bone = test.B.one

        it "should get B.one", ->
            assert( bone ).equals( 1 )