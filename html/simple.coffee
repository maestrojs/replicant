dom = undefined
$( ->
    recipe =
        title: "Munkin Pot Pie"
        description: "Savory monkey under a crispy crust"
        ingredientList: [
            {
                item: "pastry flour"
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
            item:
                value: "item"
                click: () ->
                    if this.value == "item"
                        this.value = ""
                blur: () ->
                    if this.value == ""
                        this.value = "item"
            btn:
              value: "Add"
              click: (root) ->
                list = root.ingredientList
                newItem = root.newIngredient
                list.push(
                    item: newItem.item
                    qty: newItem.quantity
                )
                this.item = ""
                this.quantity = ""
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
        rating: "none"
        ratings:
          value: "Good"
          items: [
            "Yuk city",
            "Ok",
            "Good",
            "YUMTOWN!"
          ]
        dumpus:
          click: (root) ->
            console.log JSON.stringify(root)
          value: "Click for view model state"

    doNothing = () ->

    proxy = replicant.create recipe, null, "recipe"
    cartographer = replicant.map "#recipe"

    #dom = replicant.scan "#theDoctor", ""
    #dom.write "theDoctor", proxy
    
    $( "#recipe" ).replaceWith( (cartographer.map proxy) )

    postal.channel("recipe_events").subscribe
)

#10.15.48.29