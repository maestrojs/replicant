dom = undefined
$( ->
    recipe =
        title: "Munkin Pot Pie"
        description: "Savory monkey under a crispy crust"
        ingredientList: [
            {
                item: "pastry flour"
                qty: "1 cup"
            },
            {
                item: "shortening"
                qty: "1/4 cup"
            },
            {
                item: "milk"
                qty: "1/2 cup"
            },
            {
                item: "egg"
                qty: "1 large"
            },
            {
                item: "pre-cooked monkey flesh"
                qty: "1 lb"
            },
            {
                item: "carrots"
                qty: "2 cups diced"
            },
            {
                item: "corn"
                qty: "1 cup"
            },
            {
                item: "celery"
                qty: "1 cup diced"
            },
            {
                item: "banana"
                qty: "1 sliced"
            },
        ]
        prepTime: "20 minutes"
        cookTime: "45 minutes"
        servings: 10
        prep:
            preheat: "425"


    proxy = replicant.create recipe, null, null, "recipe"
    cartographer = replicant.map "#recipe"

    #dom = replicant.scan "#theDoctor", ""
    #dom.write "theDoctor", proxy
    
    $( "#recipe" ).replaceWith( (cartographer.map proxy).toString() )
)

#10.15.48.29