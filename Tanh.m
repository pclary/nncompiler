classdef Tanh < SingleParentNode
    
    methods
        function obj = Tanh(parent, varargin)
            obj = obj@SingleParentNode(parent, varargin{:});
        end
    end
    
    
    methods (Access = protected)
        function value = evalElement(obj)
            value = tanh(obj.parents.evalImpl());
        end
        
        
        function computeScaleElement(obj)
            obj.scale = min(max(obj.parents.scale, -1), 1);
        end
        
        
        function height = getCompiledHeight(~)
            height = 1;
        end
    end
    
end
