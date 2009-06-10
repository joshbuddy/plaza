class Plaza
  class ExecutionContext
  
    attr_accessor :app
    attr_accessor :request
    attr_accessor :env
    attr_accessor :destination
    attr_accessor :route_params
    attr_accessor :available_renderers
    attr_accessor :requested_template
    attr_accessor :resolved_template
    attr_accessor :response
    attr_accessor :selected_renderer
  
    attr_reader :stage
    attr_reader :timing
  
    def at(stage, timing)
      @stage = stage
      @timing = timing
    end
  
    def computed_params(force = false)
      if !@computed_params || force
        @computed_params = {}
        route_params.each{ |hk| @computed_params[hk.first] = hk.last}
        @computed_params.merge!(request.params)
      end
      @computed_params
    end
  
  end
end