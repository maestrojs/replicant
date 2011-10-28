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

  describe "when calling indexOf", ->
    describe "on array of primitive types", ->
      test10 = {}
      before ->
        test10 =
            dummy:
                list: [1,2,3,4]
        test10 = replicant.create(test10)
      describe "with an item NOT in the array", ->
        idx = undefined
        before ->
          idx = test10.dummy.list.indexOf(7);

        it "should return -1", ->
          assert(idx).equals(-1)

      describe "with an item in the array", ->
        idx = undefined
        before ->
          idx = test10.dummy.list.indexOf(3);

        it "should return 2", ->
          assert(idx).equals(2)

    describe "on array of plain object types", ->
      test11 = {}
      item1 = {fname: 'George', lname: 'Washington'}
      item2 = {fname: 'James', lname: 'Madison'}
      item3 = {fname: 'Thomas', lname: 'Jefferson'}
      item4 = {fname: 'John', lname: 'Adams'}
      before ->
        test11 =
            dummy:
                list: [item1, item2, item3]
        test11 = replicant.create(test11)
      describe "with an item NOT in the array", ->
        idx = undefined
        before ->
          idx = test11.dummy.list.indexOf(item4);

        it "should return -1", ->
          assert(idx).equals(-1)

      describe "with an item in the array", ->
        idx = undefined
        before ->
          idx = test11.dummy.list.indexOf(item1);

        it "should return 0", ->
          assert(idx).equals(0)

    describe "on array of proxy object types", ->
      test12 = {}
      item1 = replicant.create({fname: 'George', lname: 'Washington'})
      item2 = replicant.create({fname: 'James', lname: 'Madison'})
      item3 = replicant.create({fname: 'Thomas', lname: 'Jefferson'})
      item4 = replicant.create({fname: 'John', lname: 'Adams'})
      before ->
        test12 =
            dummy:
                list: [item1, item2, item3]
        test12 = replicant.create(test12)
      describe "with an item NOT in the array", ->
        idx = undefined
        before ->
          idx = test12.dummy.list.indexOf(item4);

        it "should return -1", ->
          assert(idx).equals(-1)

      describe "with an item in the array", ->
        idx = undefined
        before ->
          idx = test12.dummy.list.indexOf(item1);

        it "should return 0", ->
          assert(idx).equals(0)

  describe "when calling lastIndexOf", ->
    describe "on array of primitive types", ->
      test13 = {}
      before ->
        test13 =
            dummy:
                list: [1,2,3,4,1,2,3,4]
        test13 = replicant.create(test13)
      describe "with an item NOT in the array", ->
        idx = undefined
        before ->
          idx = test13.dummy.list.lastIndexOf(7);

        it "should return -1", ->
          assert(idx).equals(-1)

      describe "with an item in the array", ->
        idx = undefined
        before ->
          idx = test13.dummy.list.lastIndexOf(3);

        it "should return 2", ->
          assert(idx).equals(2)

    describe "on array of plain object types", ->
      test14 = {}
      item1 = {fname: 'George', lname: 'Washington'}
      item2 = {fname: 'James', lname: 'Madison'}
      item3 = {fname: 'Thomas', lname: 'Jefferson'}
      item4 = {fname: 'John', lname: 'Adams'}
      before ->
        test14 =
            dummy:
                list: [item1, item2, item3, item1, item2, item3]
        test14 = replicant.create(test14)
      describe "with an item NOT in the array", ->
        idx = undefined
        before ->
          idx = test14.dummy.list.lastIndexOf(item4);

        it "should return -1", ->
          assert(idx).equals(-1)

      describe "with an item in the array", ->
        idx = undefined
        before ->
          idx = test14.dummy.list.lastIndexOf(item1);

        it "should return 0", ->
          assert(idx).equals(0)

    describe "on array of proxy object types", ->
      test15 = {}
      item1 = replicant.create({fname: 'George', lname: 'Washington'})
      item2 = replicant.create({fname: 'James', lname: 'Madison'})
      item3 = replicant.create({fname: 'Thomas', lname: 'Jefferson'})
      item4 = replicant.create({fname: 'John', lname: 'Adams'})
      before ->
        test15 =
            dummy:
                list: [item1, item2, item3, item1, item2, item3]
        test15 = replicant.create(test15)
      describe "with an item NOT in the array", ->
        idx = undefined
        before ->
          idx = test15.dummy.list.lastIndexOf(item4);

        it "should return -1", ->
          assert(idx).equals(-1)

      describe "with an item in the array", ->
        idx = undefined
        before ->
          idx = test15.dummy.list.lastIndexOf(item1);

        it "should return 0", ->
          assert(idx).equals(0)

  describe "when calling splice", ->
    describe "on primitive types", ->
      describe "and inserting elements", ->
        test16 = {}
        removed = undefined
        before ->
          test16 =
              list: [0,1,2,3,4,7,8]
          test16 = replicant.create(test16)
          removed = test16.list.splice(5, 0, 5, 6)
        it "should insert 5 and 6", ->
          assert(test16.list[0]).equals(0)
          assert(test16.list[1]).equals(1)
          assert(test16.list[2]).equals(2)
          assert(test16.list[3]).equals(3)
          assert(test16.list[4]).equals(4)
          assert(test16.list[5]).equals(5)
          assert(test16.list[6]).equals(6)
          assert(test16.list[7]).equals(7)
          assert(test16.list[8]).equals(8)
        it "should not have removed anything", ->
          assert(removed.length).equals(0)

      describe "and removing elements", ->
        test17 = {}
        removed = undefined
        before ->
          test17 =
              list: [0,1,2,3,4,5,6,6,6,7,8]
          test17 = replicant.create(test17)
          removed = test17.list.splice(6, 2)
        it "should match expected result", ->
          assert(test17.list[0]).equals(0)
          assert(test17.list[1]).equals(1)
          assert(test17.list[2]).equals(2)
          assert(test17.list[3]).equals(3)
          assert(test17.list[4]).equals(4)
          assert(test17.list[5]).equals(5)
          assert(test17.list[6]).equals(6)
          assert(test17.list[7]).equals(7)
          assert(test17.list[8]).equals(8)
        it "should have removed 2 elements", ->
          assert(removed.length).equals(2)
          assert(removed[0]).equals(6)
          assert(removed[1]).equals(6)

      describe "and removing + inserting elements", ->
        test18 = {}
        removed = undefined
        before ->
          test18 =
              list: [0,1,2,3,4,6,6,6,7,8]
          test18 = replicant.create(test18)
          removed = test18.list.splice(5, 2, 5)
        it "should match expected result", ->
          assert(test18.list[0]).equals(0)
          assert(test18.list[1]).equals(1)
          assert(test18.list[2]).equals(2)
          assert(test18.list[3]).equals(3)
          assert(test18.list[4]).equals(4)
          assert(test18.list[5]).equals(5)
          assert(test18.list[6]).equals(6)
          assert(test18.list[7]).equals(7)
          assert(test18.list[8]).equals(8)
        it "should have removed 2 elements", ->
          assert(removed.length).equals(2)
          assert(removed[0]).equals(6)
          assert(removed[1]).equals(6)

    describe "on complex types", ->
      describe "and inserting elements", ->
        test19 = {}
        removed = undefined
        before ->
          test19 =
              list: [{name: "George"}, {name: "Thomas"}, {name: "John"}]
          test19 = replicant.create(test19)
          removed = test19.list.splice(2, 0, {name: "James"}, {name: "Benjamin"})
        it "should insert 5 and 6", ->
          assert(test19.list[0].name).equals("George")
          assert(test19.list[1].name).equals("Thomas")
          assert(test19.list[2].name).equals("James")
          assert(test19.list[3].name).equals("Benjamin")
          assert(test19.list[4].name).equals("John")
        it "should not have removed anything", ->
          assert(removed.length).equals(0)

      describe "and removing elements", ->
        test20 = {}
        removed = undefined
        before ->
          test20 =
              list: [{name: "George"}, {name: "Thomas"}, {name: "John"}, {name: "James"},{name: "Woodrow"}, {name:"Teddy"}, {name: "Benjamin"}]
          test20 = replicant.create(test20)
          removed = test20.list.splice(4, 2)
        it "should match expected result", ->
          assert(test20.list[0].name).equals("George")
          assert(test20.list[1].name).equals("Thomas")
          assert(test20.list[2].name).equals("John")
          assert(test20.list[3].name).equals("James")
          assert(test20.list[4].name).equals("Benjamin")
        it "should have removed 2 elements", ->
          assert(removed.length).equals(2)
          assert(removed[0].name).equals("Woodrow")
          assert(removed[1].name).equals("Teddy")

      describe "and removing + inserting elements", ->
        test21 = {}
        removed = undefined
        before ->
          test21 =
              list: [{name: "George"}, {name: "Thomas"}, {name: "John"}, {name: "James"},{name: "Woodrow"}, {name:"Teddy"}, {name: "Benjamin"}]
          test21 = replicant.create(test21)
          removed = test21.list.splice(4, 2, {name: "Ronald"}, {name: "Calvin"})
        it "should match expected result", ->
          assert(test21.list[0].name).equals("George")
          assert(test21.list[1].name).equals("Thomas")
          assert(test21.list[2].name).equals("John")
          assert(test21.list[3].name).equals("James")
          assert(test21.list[4].name).equals("Ronald")
          assert(test21.list[5].name).equals("Calvin")
          assert(test21.list[6].name).equals("Benjamin")
        it "should have removed 2 elements", ->
          assert(removed.length).equals(2)
          assert(removed[0].name).equals("Woodrow")
          assert(removed[1].name).equals("Teddy")

  describe "when calling slice", ->
    describe "on primitive types", ->
      describe "with one argument", ->
        test22 = {}
        result = undefined
        before ->
          test22 =
              list: [1,2,3,4,5,6,7,8,9,10]
          test22 = replicant.create(test22)
          result = test22.list.slice(5)
        it "should return the expected values", ->
          assert(result.length).equals(5);
          assert(result[0]).equals(6);
          assert(result[1]).equals(7);
          assert(result[2]).equals(8);
          assert(result[3]).equals(9);
          assert(result[4]).equals(10);
      describe "with two arguments", ->
        test23 = {}
        result = undefined
        before ->
          test23 =
              list: [1,2,3,4,5,6,7,8,9,10]
          test23 = replicant.create(test23)
          result = test23.list.slice(5, 9)
        it "should return the expected values", ->
          assert(result.length).equals(4);
          assert(result[0]).equals(6);
          assert(result[1]).equals(7);
          assert(result[2]).equals(8);
          assert(result[3]).equals(9);
      describe "with one negative value argument", ->
        test24 = {}
        result = undefined
        before ->
          test24 =
              list: [1,2,3,4,5,6,7,8,9,10]
          test24 = replicant.create(test24)
          result = test24.list.slice(-2)
        it "should return the expected values", ->
          assert(result.length).equals(2);
          assert(result[0]).equals(9);
          assert(result[1]).equals(10);
      describe "with two negative value arguments", ->
        test25 = {}
        result = undefined
        before ->
          test25 =
              list: [1,2,3,4,5,6,7,8,9,10]
          test25 = replicant.create(test25)
          result = test25.list.slice(-4, -2)
        it "should return the expected values", ->
          assert(result.length).equals(2);
          assert(result[0]).equals(7);
          assert(result[1]).equals(8);

    describe "on complex types", ->
      describe "with one argument", ->
        test26 = {}
        result = undefined
        before ->
          test26 =
              list: [{name:"Jim"}, {name:"Alex"}, {name:"Chris"}, {name:"Ian"}]
          test26 = replicant.create(test26)
          result = test26.list.slice(2)
        it "should return the expected values", ->
          assert(result.length).equals(2);
          assert(result[0].name).equals("Chris");
          assert(result[1].name).equals("Ian");
      describe "with two arguments", ->
        test27 = {}
        result = undefined
        before ->
          test27 =
              list: [{name:"Jim"}, {name:"Alex"}, {name:"Chris"}, {name:"Ian"}]
          test27 = replicant.create(test27)
          result = test27.list.slice(0, 2)
        it "should return the expected values", ->
          assert(result.length).equals(2);
          assert(result[0].name).equals("Jim");
          assert(result[1].name).equals("Alex");
      describe "with one negative value argument", ->
        test28 = {}
        result = undefined
        before ->
          test28 =
              list: [{name:"Jim"}, {name:"Alex"}, {name:"Chris"}, {name:"Ian"}]
          test28 = replicant.create(test28)
          result = test28.list.slice(-2)
        it "should return the expected values", ->
          assert(result.length).equals(2);
          assert(result[0].name).equals("Chris");
          assert(result[1].name).equals("Ian");
      describe "with two negative value arguments", ->
        test29 = {}
        result = undefined
        before ->
          test29 =
              list: [{name:"Jim"}, {name:"Alex"}, {name:"Chris"}, {name:"Ian"}]
          test29 = replicant.create(test29)
          result = test29.list.slice(-4, -2)
        it "should return the expected values", ->
          assert(result.length).equals(2);
          assert(result[0].name).equals("Jim");
          assert(result[1].name).equals("Alex");