QUnit.specify "array", ->
    describe "array", ->

        test =
            dummy:
                one: 1
                two: 2
            list: [ { one: 1 }, { two: 2 }, { three: 3 }]

        test = replicant.create(
            test
        )
        
        test.list.push( {four: 4} )

        test.list[2].three = 8

        it "should replace 3rd item", ->
            assert( test.list[2].three == 8).isTrue()

        it "should have added 4", ->
            assert( test.list[3].four == 4 ).isTrue()