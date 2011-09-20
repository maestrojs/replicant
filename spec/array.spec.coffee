QUnit.specify "array", ->
    describe "array", ->

        test =
            dummy:
                one: 1
                two: 2
            list: [1,2,3]

        test = replicant.create(
            test
        )
        
        test.list.push( 4 )

        test.list[2] = 8

        it "should replace 3rd item", ->
            assert( test.list[2] == 8).isTrue()

        it "should have added 4", ->
            assert( test.list[3] == 4 ).isTrue()