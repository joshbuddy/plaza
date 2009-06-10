require File.expand_path(File.dirname(__FILE__) + '/plaza/execution_context')

class Plaza

  attr_accessor :router, :mapper, :dispatcher, :selector, :renderer_picker, :template_picker
  Filters = Struct.new(:router, :dispatcher, :template_picker, :renderer_picker, :selected_renderer)
  
  def register_renderer(name, &block)
    @renderers[name] = block
  end
  
  def initialize(&block)
    @renderers = {}
    @before = Filters.new
    @after = Filters.new
    instance_eval(&block)
  end
  
  def before(type, &block)
    @before[type] ||= []
    @before.send(type) << block
  end
  
  def after
    @after[type] ||= []
    @after.send(type) << block
  end

  def callback(type)
    @context.at(type, :before)
    (before = @before.send(type)) && before.each{ |filter| filter.call(@context) }
    yield
    @context.at(type, :after)
    (after = @after.send(type)) && after.each{ |filter| filter.call(@context) }
  end

  def call(env)
    @context = ExecutionContext.new
    @context.app = self
    @context.env = env
    @context.request = Rack::Request.new(env)
    @context.available_renderers = @renderers
    
    Thread.current[:context] = @context

    mapper.run(router)
    
    callback(:router) { router.call(@context) }
    
    if @context.destination
      callback(:dispatcher) { dispatcher.call(@context) }
      unless @context.response
        callback(:template_picker) { template_picker.call(@context) }
        callback(:renderer_picker) { renderer_picker.call(@context) }
        callback(:selected_renderer) { @context.selected_renderer.call(@context) }
      end
    end
    
    if @context.response
      @context.response
    elsif @or
      @or.call(env)
    else
      raise
    end
  end
  
  def or(app)
    @or = app
  end
  
end