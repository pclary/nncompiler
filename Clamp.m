classdef Clamp < SingleParentNode
    
    properties
        bounds(2, 1) double
    end
    
    
    methods
        function obj = Clamp(parent, bounds, varargin)
            obj = obj@SingleParentNode(parent, varargin{:});
            obj.bounds = bounds;
        end
    end
    
    
    methods (Access = protected)
        function value = evalElement(obj)
            value = min(max(obj.parents.evalImpl(), obj.bounds(1)), obj.bounds(2));
        end
        
        
        function computeScaleElement(obj)
            obj.scale = min(max(obj.parents.scale, obj.bounds(1)), obj.bounds(2));
        end
        
        
        function height = getCompiledHeight(~)
            height = 1;
        end
        
        
        function [headObj, tailObj] = replaceNonlinearElement(obj)
            m = mean(obj.bounds);
            d = diff(obj.bounds) / 2;
            tailObj = Linear(obj.parents, [-m/d 1/d]);
            headObj = Linear(Tanh(tailObj), [m d]);
        end
    end
    
end
