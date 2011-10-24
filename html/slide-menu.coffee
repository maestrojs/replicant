Category = ( name, meals ) ->
  category =
    title:
      value: name
      display: false
      click: (x,y) ->
        if not this.display
          details = $(y.control).next()
          details.animate(
            { height: this.ancestors[0].choices.length * 40 },
            300, "easeOutQuad"
          )
          this.display = true
        else
          details = $(y.control).next()
          details.animate(
            { height: 0 },
            400, "easeOutQuad"
          )
          this.display = false

    choices: meals or= []
  category

meals = [
  new Category("Breakfast", ["Scramby Eggs","Waffoes","Cap'n Crunch","Mega Muffin"]),
  new Category "Lunch",
  new Category "Dinner"
  ]

$( ->
  replicant.create meals, null, "meals"
  cartographer.map "#meals"
  cartographer.apply "meals", replicant["meals"]

  replicant["meals"][1].choices = ["PB & JamJamz","Turkey n' Cheeserz","Soup"]
  
)