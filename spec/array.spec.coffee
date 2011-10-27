QUnit.specify "array", ->
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
  describe "array", ->
    describe "Simple Operation", ->

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

    describe "when reversing", ->
      test2 = {}
      before ->
        test2 =
            dummy:
                one: 1
                two: 2
                list: [
                    { nega: -1 },
                    { one: 1 },
                    { two: 2 },
                    { three: 0 },
                    { uber: 100 } ]

        test2 = replicant.create(test2)
        test2.dummy.list.reverse()

      it "should reverse the list", ->
        assert(test2.dummy.list[0].uber).equals(100)
        assert(test2.dummy.list[1].three).equals(0)
        assert(test2.dummy.list[2].two).equals(2)
        assert(test2.dummy.list[3].one).equals(1)
        assert(test2.dummy.list[4].nega).equals(-1)

    describe "when reversing twice", ->
      test3 = {}
      before ->
        test3 =
            dummy:
                one: 1
                two: 2
                list: [
                    { nega: -1 },
                    { one: 1 },
                    { two: 2 },
                    { three: 0 },
                    { uber: 100 } ]

        test3 = replicant.create(test3)
        test3.dummy.list.reverse()
        test3.dummy.list.reverse()

      it "should reverse the list", ->
        assert(test3.dummy.list[4].uber).equals(100)
        assert(test3.dummy.list[3].three).equals(0)
        assert(test3.dummy.list[2].two).equals(2)
        assert(test3.dummy.list[1].one).equals(1)
        assert(test3.dummy.list[0].nega).equals(-1)

    describe "when sorting", ->
      describe "with asc compare function", ->
        test4 = {}
        sorter = (x,y) ->
          if x.item < y.item
            -1
          else if y.item < x.item
            1
          else
            0
        before ->
          test4 =
              dummy:
                  one: 1
                  two: 2
                  list: [
                      { item: 12 },
                      { item: 47 },
                      { item: 2  },
                      { item: 33 },
                      { item: 29 } ]

          test4 = replicant.create(test4)
          test4.dummy.list.sort(sorter)

        it "should sort the list ascending", ->
          assert(test4.dummy.list[0].item).equals(2)
          assert(test4.dummy.list[1].item).equals(12)
          assert(test4.dummy.list[2].item).equals(29)
          assert(test4.dummy.list[3].item).equals(33)
          assert(test4.dummy.list[4].item).equals(47)

      describe "with desc compare function", ->
        test5 = {}
        sorter = (x,y) ->
          if x.item < y.item
            1
          else if y.item < x.item
            -1
          else
            0
        before ->
          test5 =
              dummy:
                  one: 1
                  two: 2
                  list: [
                      { item: "Jim" },
                      { item: "Alex" },
                      { item: "Kevin"  },
                      { item: "Chris" },
                      { item: "Ian" } ]

          test5 = replicant.create(test5)
          test5.dummy.list.sort(sorter)

        it "should sort the list descending", ->
          assert(test5.dummy.list[0].item).equals("Kevin")
          assert(test5.dummy.list[1].item).equals("Jim")
          assert(test5.dummy.list[2].item).equals("Ian")
          assert(test5.dummy.list[3].item).equals("Chris")
          assert(test5.dummy.list[4].item).equals("Alex")

      describe "with no compare function", ->
        test6 = {}
        before ->
          test6 =
              dummy:
                  one: 1
                  two: 2
                  list: [8,6,7,5,3,0,9]

          test6 = replicant.create(test6)
          test6.dummy.list.sort()

        it "should sort the list ascending using primitive type comparison", ->
          assert(test6.dummy.list[0]).equals(0)
          assert(test6.dummy.list[1]).equals(3)
          assert(test6.dummy.list[2]).equals(5)
          assert(test6.dummy.list[3]).equals(6)
          assert(test6.dummy.list[4]).equals(7)
          assert(test6.dummy.list[5]).equals(8)
          assert(test6.dummy.list[6]).equals(9)

  describe "When calling join()", ->
    describe "without a custom separator", ->
      test7 = {}
      expected = "Paul,John,George,Ringo"
      result = ""
      before ->
        test7 =
            dummy:
                list: ["Paul", "John", "George", "Ringo"]

        test7 = replicant.create(test7)
        result = test7.dummy.list.join()
        result

      it "should have a result matching the expected output", ->
        assert(result).equals(expected)

    describe "with a custom separator", ->
      test8 = {}
      expected = "Paul | John | George | Ringo"
      result = ""
      before ->
        test8 =
            dummy:
                list: ["Paul", "John", "George", "Ringo"]

        test8 = replicant.create(test8)
        result = test8.dummy.list.join(" | ")
        result

      it "should have a result matching the expected output", ->
        assert(result).equals(expected)


  describe "when calling toString()", ->
    test9 = {}
    expected = "Paul,John,George,Ringo"
    result = ""
    before ->
      test9 =
          dummy:
              list: ["Paul", "John", "George", "Ringo"]

      test9 = replicant.create(test9)
      result = test9.dummy.list.join()
      result

    it "should have a result matching the expected output", ->
      assert(result).equals(expected)
