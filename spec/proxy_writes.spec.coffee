QUnit.specify "write proxy", ->
    describe "proxy", ->

        setted = []

        onSet = ( x, y, z ) ->
            setted.push { property: x, value: y, old: z }

        theFellowship =
            title: ""
            humans: [
                {
                    name: "Boromir",
                    char_class: "Warrior"
                }
            ]

        proxy = replicant.create theFellowship, null, onSet
        proxy.title = "Of The Ring"
        proxy.humans.push { name: "Aragorn", char_class: "Ranger" }
        proxy.humans[0].char_class = "Hero"

        it "should capture title write", ->
            assert( _.any setted, (x) -> x.property == "title" ).isTrue()

        it "should expand collection", ->
            assert( proxy.humans.length == 2 ).isTrue()

        it "should capture write of nested collection element property", ->
            assert( _.any setted, (x) -> x.property == "humans.0.char_class" ).isTrue()

        it "should capture push as write", ->
            assert( _.any setted, (x) -> x.property == "humans.1" ).isTrue()