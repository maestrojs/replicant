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
        
        test.dummy.list.push( {four: 4} )

        test.dummy.list[2].three = 8

        it "should replace 3rd item", ->
            assert( test.dummy.list[2].three ).equals( 8 )

        it "should have added 4", ->
            assert( test.dummy.list[3].four ).equals( 4 )