QUnit.specify "read proxy", ->
    describe "proxy", ->

        getted = []

        onEvent = ( w, x, y, z ) ->
            getted.push { property: x, value: z.value}

        drWho =
            name: "The Doctor"
            age: 999
            craft:
                name: "Tardis"
                shapeShift: false
                timeTravel: true
                spaceTravel: true
            companions: [
                { name: "Rose", age: "25" },
                { name: "Marta", age: "25" }
            ]
            
        describe "member access", ->

            drWho = replicant.create drWho, onEvent
            
            #before ->
            name = drWho.name
            canShift = drWho.craft.shapeShift
            rosesAge = drWho.companions[0].age

            it "should capture property read", ->
                assert( _.any getted, (x) -> x.property == "name" ).isTrue()

            it "should capture nested property read", ->
                assert( _.any getted, (x) -> x.property == "craft.shapeShift" ).isTrue()

            it "should capture read of nested collection element property", ->
                assert( _.any getted, (x) -> x.property == "companions.0.age" ).isTrue()