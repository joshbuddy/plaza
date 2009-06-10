router.add_route('/blah').to({:controller => :MainController, :action => :blah})
router.add_route('/:id').to({:controller => :MainController, :action => :index})
