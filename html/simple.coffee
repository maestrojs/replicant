dom = undefined

Ingredient = ( item, qty ) ->

    hovered: false
    click: (r,x) -> JSON.stringify console.log.info
    mouseover: (r,x) ->
        @display.showbtn.hide = false
        x.control.className = "ingredient highlight"
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


Step = ( step, detail ) ->
    {
        step: step
        detail: detail
    }

BuildIngredientList = ( list, recipe ) ->
    recipe.ingredients.push( new Ingredient( x[0],x[1] ) ) for x in list

BuildSteps = ( list, recipe ) ->
    recipe.steps.push( new Step( x[0], x[1] ) ) for x in list

Recipe = ( Title, Description, Ingredients, Steps ) ->
    recipe =
        title:
          value: Title
          hovered: false
          click: (r,x) ->
            recipe = this.ancestors[0]
            alias = replicant.create recipe.getOriginal(), null, "recipe"

            $( "#recipe" ).replaceWith( (recipeTemplate.map alias) )
          mouseover: (r,x) ->
              #x.control.className = "highlight"
              @hovered = true
          mouseout: (r,y) ->
              @hovered = false
              #window.setTimeout ((x) ->
              #    if not x.hovered
              #        y.control.className = "ingredient"
              #    )
              #    , 100
              #    , this

        description: Description
        ingredients: []
        steps: []

        dumpus:
          click: (root) ->
            console.log JSON.stringify(root)
          value: "Click for view model state"

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
                list = root.ingredients
                newItem = root.newIngredient
                list.push(
                    new Ingredient newItem.item, newItem.quantity
                  )
                this.ancestors[0].item = ""
                this.ancestors[0].quantity = ""

    BuildIngredientList( Ingredients, recipe )
    BuildSteps( Steps, recipe )
    recipe

recipe1 = new Recipe(
        "Monkey Pot Pie",
        "Savory chunks of monkey under a crispy crust",
        [
            ["pastry flour","1 cup"],
            ["shortening","1/2 cup"],
            ["milk","1/2 cup"],
            ["egg","1 large"],
            ["adult monkey","1 lb"],
            ["carrots","2 cups diced"],
            ["corn","1 cup"],
            ["celery","1 cup diced"],
            ["banana","1 sliced"],
        ],
        [
            ["preheat","the oven to 425."],
            ["combine","everything in big friggen bowl."],
            ["trick","the monkey into the bowl with the banana."],
            ["bake","until the monkey stops screaming."]
        ]
    )

recipe2 = new Recipe(
    "Beer cheese soup",
    "An excuse to eat beer",
    [
        ["Pabst Blue Ribbon","6 pack"],
        ["Mr. Block of Cheese",""],
    ],
    [
        ["eat","the entire Mr. Block of Cheese."],
        ["chug","all the beer."],
    ]
)

recipes = [ recipe1, recipe2 ]

list = replicant.create recipes, null, "recipes"
recipeTemplate = {}
listTemplate = {}

$( ->

    recipeTemplate = replicant.map "#recipe"
    listTemplate = replicant.map "#recipes > #list"

    $( "#recipes > #list" ).replaceWith( listTemplate.map list )

    postal.channel("recipes_events").subscribe
    postal.channel("recipe_events").subscribe
)
