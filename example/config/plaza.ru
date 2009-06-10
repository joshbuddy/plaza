require 'rubygems'
require '../lib/plaza'
require 'usher'
require 'erb'
class AwesomeMapper

  attr_accessor :options
  attr_reader :router
  
  def initialize(config)
    (@configs = []) << config
  end
    
  def add_configuration_file(file)
    @configs << []
  end
  
  def run(receiver)
    @router = receiver
    @configs.each do |config|
      eval(IO.read(config))
    end
  end
  
end

class SimpleController

  attr_reader :params

  def _dispatch(name, context)
    @response_sent = false
    @_context = context
    @controller_name = context.destination[:controller]
    send(name)
  end  
  
  def render(name)
    raise if @response_sent
    unless name['/']
      name[0,0] = '/'
      name[0,0] = @controller_name.to_s
    end
    @_context.requested_template = name
    @response_sent = true
  end
  
  def redirect_to(url)
    raise if @response_sent
    @_context.response = [302, {'Location' => url}, []]
    @response_sent = true
  end
end

class MainController < SimpleController

  def index
    render 'index'
  end
  
  def blah
    redirect_to "http://www.slashdot.org/"
  end
end

class SimpleDispatcher
  
  def call(context)
    case context.destination
    when Hash
      controller_name = context.destination[:controller]
      controller = Kernel.const_get(controller_name).new
      action_name = context.destination[:action] || controller.default_action
      controller.send(:_dispatch, action_name, context)
    when Proc
      proc.call
    end
    
  end
  
end

class SimplePicker
  
  def initialize(path)
    @path = path
  end
  
  def call(context)
    context.resolved_template = File.join(@path,  "#{context.requested_template}.erb")
  end
end

class ErbRenderer
  
  def render(context)
    params = context.computed_params
    result = ERB.new(IO.read(context.resolved_template)).result(binding)
    [200, {'Content-type' => 'text/html', 'Content-length' => result.size.to_s}, [result]]
  end
  
end

class UsherFish < Usher
  
  def call(context)
    if response = recognize(context.request)
      context.route_params = response.params
      context.destination = response.path.route.destination
    end
  end
end

run Plaza.new {
  self.mapper = AwesomeMapper.new('config/routes.rb')
  self.router = UsherFish.new
  self.dispatcher = SimpleDispatcher.new
  self.renderer_picker = proc{|context| context.selected_renderer = context.available_renderers.values.first}
  self.template_picker = SimplePicker.new(File.join(File.dirname(__FILE__), '..', 'views'))
  renderer = ErbRenderer.new
  register_renderer(:'.erb') do |context|
    context.response = renderer.render(context)
  end
}#.or(proc {|env| [200, {'Content-length' => '5', 'Content-type' => 'text/plain'}, ['oops!']]})
