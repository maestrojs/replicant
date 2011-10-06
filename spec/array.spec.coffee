QUnit.specify "array", ->
    describe "array", ->

        test =
            dummy:
                one: 1
                two: 2
                list: [
                    { nega: -1 },
                    { one: 1 },
                    { two: 2 },
                    { three: 0 },
                    { uber: 100 } ]

        test = replicant.create(
            test
        )

        shifted = test.dummy.list.shift()
        popped = test.dummy.list.pop()
        
        test.dummy.list.unshift( { zero: 0 } )
        test.dummy.list.push( {four: 4} )

        test.dummy.list[3].three = 3

        it "index 0 should be 0", ->
            assert( test.dummy.list[0].zero ).equals( 0 )
            
        it "index 1 should be 1", ->
            assert( test.dummy.list[1].one ).equals( 1 )

        it "index 2 should be 2", ->
            assert( test.dummy.list[2].two ).equals( 2 )

        it "index 3 should be 3", ->
            assert( test.dummy.list[3].three ).equals( 3 )

        it "index 4 should be 4", ->
            assert( test.dummy.list[4].four ).equals( 4 )

        it "shifted item should be -1", ->
            assert( shifted.nega ).equals( -1 )

        it "popped item should be 100", ->
            assert( popped.uber ).equals( 100 )