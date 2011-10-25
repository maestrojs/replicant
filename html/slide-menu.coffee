Category = ( name ) ->
  category =
    title:
      value: name
      click: (r,x) ->
        target = $(x.control).parent().parent()
        target.animate(
          marginLeft: target.outerWidth()
        )

  category

meals = [ new Category("Breakfast"), new Category("Lunch"), new Category "Dinner" ]
mealsProxy = replicant.create meals, null, "meals"

$( ->
  cartographer.map "#meals"
  cartographer.apply "meals", mealsProxy
)