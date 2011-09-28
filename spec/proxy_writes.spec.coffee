QUnit.specify "write proxy", ->
    describe "proxy", ->

        setted = []

        onSet = ( w, x, y, z ) ->
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

        subProxy = replicant.create { name: "Faromir", char_class: "Warrior" }, null, onSet
        proxy.humans.push subProxy

        #proxy["humans.2.char_class"] = "Hero"
        proxy.humans[2].char_class = "Hero"
        console.log JSON.stringify setted

        it "should capture title write", ->
            assert( _.any setted, (x) -> x.property == "title" ).isTrue()

        it "should expand collection", ->
            assert( proxy.humans.length == 3 ).isTrue()

        it "should capture write of nested collection element property", ->
            assert( _.any setted, (x) -> x.property == "humans.0.char_class" ).isTrue()

        it "should capture write of nested collection element property", ->
            assert( _.any setted, (x) -> x.property == "humans.2.char_class" ).isTrue()

        it "should capture push as write", ->
            assert( _.any setted, (x) -> x.property == "humans.1" ).isTrue()

        it "should capture push as write", ->
            assert( _.any setted, (x) -> x.property == "humans.2" ).isTrue()