dom = undefined
$( ->

    ingredient = ( item, qty ) ->
        mouseover: () -> this.showbtn.hide = false
        mouseout: () -> this.showbtn.hide = true
        item: item
        qty: qty
        showbtn:
          value: "edit"
          hide: true
          click: (p, x) ->
            console.log this.edit.hide
        edit:
          hide: true
          item: item
          qty: qty

    recipe =
        title: "Munkin Pot Pie"
        description: "Savory monkey under a crispy crust"
        ingredientList: [
            new ingredient "pastry flour", "1 cup"
            new ingredient "shortening", "1/4 cup"
            new ingredient "milk", "1/2 cup"
            new ingredient "egg", "1 large"
            new ingredient "adult monkey", "1 lb"
            new ingredient "carrots", "2 cups diced"
            new ingredient "corn", "1 cup"
            new ingredient "celery", "1 cup diced"
            new ingredient "banana", "1 sliced"
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
                    new ingredient newItem.item, newItem.quantity
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