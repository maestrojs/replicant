dom = undefined

Ingredient = ( item, qty ) ->

    mouseover: () ->
        @display.showbtn.hide = false
    mouseout: () ->
        @display.showbtn.hide = true
    display:
        item: item
        qty: qty
        showbtn:
            value: "edit"
            hide: true
            click: (p, x) ->
                console.log "hide"
    edit:
        item: item
        qty: qty
        okbtn:
            value: "ok"
            click: (p, x) ->
                console.log "ok"
        cancelbtn:
            value: "cancel"
            click: (p, x) ->
                console.log "ok"
        hide: true

$( ->

    recipe =
        title: "Munkin Pot Pie"
        description: "Savory monkey under a crispy crust"
        ingredientList: [
            new Ingredient "pastry flour", "1 cup"
            new Ingredient "shortening", "1/4 cup"
            new Ingredient "milk", "1/2 cup"
            new Ingredient "egg", "1 large"
            new Ingredient "adult monkey", "1 lb"
            new Ingredient "carrots", "2 cups diced"
            new Ingredient "corn", "1 cup"
            new Ingredient "celery", "1 cup diced"
            new Ingredient "banana", "1 sliced"
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
                    new Ingredient newItem.item, newItem.quantity
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
    
    $( "#recipe" ).replaceWith( (cartographer.map proxy) )

    postal.channel("recipe_events").subscribe
)

#10.15.48.29