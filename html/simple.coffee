dom = undefined
$( ->
    doctor =
        name: "The Doctor"
        onclick: "console.log('I am The Doctor!');"
        companions:
            [
                {
                    name: "Rose",
                    age: 26,
                    adventures: ["Bad Wolf","Dalek"]
                    onclick: "console.log('hi');"
                },
                {
                    name: "Martha",
                    age: 26,
                    adventures: ["Family of Blood","Being Human"]
                }
            ]
        craft:
            name: "Tardis"

    proxy = replicant.create doctor, null, null, "theDoctor"
    cartographer = replicant.map "#theDoctor"

    #dom = replicant.scan "#theDoctor", ""
    #dom.write "theDoctor", proxy
    
    $( "#theDoctor" ).replaceWith( (cartographer.map proxy).toString() )
)

#10.15.48.29