dom = undefined
$( ->
    recipe =
        hurp: () -> console.log "test"
        title: "Munkin Pot Pie"
        description: "Savory monkey under a crispy crust"
        ingredientList: [
            {
                item: {
                    text: "pastry flour"
                    onclick: () -> @hurp()
                }
                qty: "1 cup"
            }
            {
                item: "shortening"
                qty: "1/4 cup"
            }
            {
                item: "milk"
                qty: "1/2 cup"
            }
            {
                item: "egg"
                qty: "1 large"
            }
            {
                item: "adult monkey"
                qty: "1 lb"
            }
            {
                item: "carrots"
                qty: "2 cups diced"
            }
            {
                item: "corn"
                qty: "1 cup"
            }
            {
                item: "celery"
                qty: "1 cup diced"
            }
            {
                item: "banana"
                qty: "1 sliced"
            }
        ]
        newIngredient:
            quantity: "qty"
            item: "item"
            btn:
              text: "Add"
              onclick: () -> console.log "shuclackity"
        prepTime: "20 minutes"
        cookTime: "45 minutes"
        servings: 10
        prep: [
          {
            step: "preheat"
            detail: " the oven to 425."
          }
          {
            step: "combine"
            detail: " everything in a big friggin bowl."
          }
          {
            step: "trick"
            detail: " the monkey into the bowl with the banana."
          }
          {
            step: "bake"
            detail: " until the monkey stops screaming."
          }
        ]


    proxy = replicant.create recipe, null, null, "recipe"
    cartographer = replicant.map "#recipe"

    #dom = replicant.scan "#theDoctor", ""
    #dom.write "theDoctor", proxy
    
    $( "#recipe" ).replaceWith( (cartographer.map proxy) )
)

#10.15.48.29