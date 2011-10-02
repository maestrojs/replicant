dom = undefined

Ingredient = ( item, qty ) ->

    hovered: false
    click: (r,x) -> JSON.stringify console.log.info
    mouseover: (r,x) ->
        @display.showbtn.hide = false
        x.control.className = "ingredient ingredient-highlight"
        this.display.showbtn.class = "button inline-block"
        @hovered = true
    mouseout: (r,y) ->
        @hovered = false
        window.setTimeout ((x) ->
            if not x.hovered
                x.display.showbtn.hide = true
                x.display.showbtn.class = "button"
                y.control.className = "ingredient"
            )
            , 100
            , this
    display:
        hide: false
        item: item
        qty: qty
        showbtn:
            class: "button"
            value: "edit"
            hide: true
            click: (p, x) ->
                editor = this.ancestors[1].edit
                display = this.ancestors[0]
                display.hide = true
                editor.hide = false
    edit:
        item: item
        qty: qty
        okbtn:
            value: "ok"
            click: (p, x) ->
                editor = this.ancestors[0]
                display = this.ancestors[1].display
                editor.hide = true
                display.hide = false
                display.item = editor.item
                display.qty = editor.qty
        cancelbtn:
            value: "cancel"
            click: (p, x) ->
                editor = this.ancestors[0]
                display = this.ancestors[1].display
                editor.hide = true
                display.hide = false
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
            quantity:
                value: ""
                click: (x, y) -> y.control.select()
            item:
                value: ""
                click: (x, y) -> y.control.select()
            btn:
              value: "Add"
              click: (root) ->
                list = root.ingredientList
                newItem = root.newIngredient
                list.push(
                    new Ingredient newItem.item, newItem.quantity
                  )
                this.ancestors[0].item = ""
                this.ancestors[0].quantity = ""
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