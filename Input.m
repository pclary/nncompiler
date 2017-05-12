classdef Input < Node
    
    properties
        fixedScale(1, 2) double
    end
    
    methods
        function obj = Input(scale, varargin)
            obj = obj@Node(Node.empty(), varargin{:});
            obj.fixedScale = scale;
        end
    end
    
    
    methods (Access = protected)
        function value = evalElement(obj)
            value = obj.value;
        end
        
        
        function computeScaleElement(obj)
            obj.scale = obj.fixedScale;
        end
        
        
        function inputs = findInputsImpl(obj)
            inputs = obj;
            obj.flag = true;
        end
        
        
        function height = getCompiledHeight(~)
            height = 1;
        end
    end
    
end
