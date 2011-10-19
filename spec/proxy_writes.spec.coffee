QUnit.specify "write proxy", ->
    describe "proxy", ->

        setted = []

        onSet = ( w, x, y, z ) ->
            setted.push { property: x, value: z.value, old: z.previous }

        theFellowship =
            title: ""
            humans: [
                {
                    name: "Boromir",
                    char_class: "Warrior"
                }
            ]

        proxy = replicant.create theFellowship, onSet
        proxy.title = "Of The Ring"
        proxy.humans.push { name: "Aragorn", char_class: "Ranger" }
        proxy.humans[0].char_class = "Hero"

        subProxy = replicant.create { name: "Faromir", char_class: "Warrior" }, onSet
        proxy.humans.push subProxy

        proxy.humans[2].char_class = "Hero"
        proxy["humans.2.char_class"] = "Dead Guy :("

        it "should capture title write", ->
            assert( _.any setted, (x) -> x.property == "title" ).isTrue()

        it "should expand collection", ->
            assert( proxy.humans.length ).equals( 3 )

        it "should have changed sub proxy property", ->
            assert( proxy.humans["2.char_class"]).equals( "Dead Guy :(" )

        it "should capture write of nested collection element property", ->
            assert( _.any setted, (x) -> x.property == "humans.0.char_class" ).isTrue()

        it "should capture write of nested collection element property", ->
            assert( _.any setted, (x) -> x.property == "humans.2.char_class" ).isTrue()

        it "should capture push as write", ->
            assert( _.any setted, (x) -> x.property == "humans.1" ).isTrue()

        it "should capture push as write", ->
            assert( _.any setted, (x) -> x.property == "humans.2" ).isTrue()