classdef Rectify < SingleParentNode
    
    methods
        function obj = Rectify(parent, varargin)
            obj = obj@SingleParentNode(parent, varargin{:});
        end
    end
    
    
    methods (Access = protected)
        function value = evalElement(obj)
            value = max(obj.parents.evalImpl(), 0);
        end
        
        
        function computeScaleElement(obj)
            obj.scale = max(obj.parents.scale, 0);
        end
        
        
        function height = getCompiledHeight(~)
            height = 1;
        end
        
        
        function [headObj, tailObj] = replaceNonlinearElement(obj)
            a = max(abs(obj.parents.scale));
            tailObj = [
                Linear(obj.parents, [-0.17411 3.9827/a]) ...
                Linear(obj.parents, [-1.5403 2.0606/a]) ...
                Linear(obj.parents, [-0.083809 4.0249/a])];
            h1 = Tanh(tailObj(1));
            h2 = Tanh(tailObj(2));
            h3 = Tanh(tailObj(3));
            headObj = Linear([h1 h2 h3], [0.62512 1.5796 0.49797 -1.4523]*a);
        end
    end
    
end
