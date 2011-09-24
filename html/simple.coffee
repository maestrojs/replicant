dom = undefined
$( ->
    doctor =
        name: "The Doctor"
        companions:
            [
                { name: "Rose", age: 26 },
                { name: "Martha", age: 26 }
            ]
        craft:
            name: "Tardis"

    proxy = replicant.create doctor, null, null, "theDoctor"
    cartographer = replicant.map "#theDoctor"

    #dom = replicant.scan "#theDoctor", ""
    #dom.write "theDoctor", proxy

    console.log cartographer.map( proxy ).toString()
    $( "#theDoctor" ).replaceWith( (cartographer.map proxy).toString() )
)

#10.15.48.29