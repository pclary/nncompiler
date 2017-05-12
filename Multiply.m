classdef Multiply < Node
    
    methods
        function obj = Multiply(parents, varargin)
            obj = obj@Node(parents, varargin{:});
            assert(numel(obj.parents) == 2);
        end
    end
    
    methods (Access = protected)
        function value = evalElement(obj)
            value = prod(obj.parents.evalImpl());
        end
        
        
        function computeScaleElement(obj)
            obj.scale = [1 1];
            for i = 1:numel(obj.parents)
                s = obj.scale' .* obj.parents(i).scale;
                obj.scale = [min(s(:)) max(s(:))];
            end
        end
        
        
        function height = getCompiledHeight(~)
            height = 1;
        end
        
        
        function [headObj, tailObj] = replaceNonlinearElement(obj)
            a = max(abs(obj.parents(1).scale));
            b = max(abs(obj.parents(2).scale));
            tailObj = [...
                Linear(obj.parents, [1.1743 -0.218/a 0.218/b]) ...
                Linear(obj.parents, [-1.1743 0.218/a 0.218/b]) ...
                Linear(obj.parents, [1.1743 0.218/a -0.218/b]) ...
                Linear(obj.parents, [-1.1743 -0.218/a -0.218/b])];
            h1 = Tanh(tailObj(1));
            h2 = Tanh(tailObj(2));
            h3 = Tanh(tailObj(3));
            h4 = Tanh(tailObj(4));
            headObj = Linear([h1 h2 h3 h4], [0 1 1 1 1]*a*b*10);
        end
    end
    
end
