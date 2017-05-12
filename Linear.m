classdef Linear < Node
    
    properties
        weights(:, 1) double 
    end
    
    
    methods
        function obj = Linear(parents, weights, varargin)
            % Make it easier to specify no parents by using []
            if ~numel(parents)
                parents = Node.empty();
            end
            
            obj = obj@Node(parents, varargin{:});
            obj.weights = weights;
            assert(numel(obj.weights) == numel(obj.parents) + 1);
        end
    end
    
    
    methods (Access = protected)
        function value = evalElement(obj)
            value = obj.weights' * [1 obj.parents.evalImpl()]';
        end
        
        
        function computeScaleElement(obj)
            obj.scale = [obj.weights(1) obj.weights(1)];
            for i = 1:numel(obj.parents)
                s = obj.weights(1 + i) * obj.parents(i).scale;
                obj.scale(1) = obj.scale(1) + min(s);
                obj.scale(2) = obj.scale(2) + max(s);
            end
        end
        
        
        function height = getCompiledHeight(~)
            height = 0;
        end
        
        
        function simplifyElement(obj)
            i = 1;
            while i <= numel(obj.parents)
                p = obj.parents(i);
                if isa(p, 'Linear')
                    obj.weights(1) = obj.weights(1) + obj.weights(1 + i) * p.weights(1);
                    for j = 1:numel(p.parents)
                        if any(obj.parents == p.parents(j))
                            k = find(obj.parents == p.parents(j), 1);
                            obj.weights(1 + k) = obj.weights(1 + k) + ...
                                obj.weights(1 + i) * p.weights(1 + j);
                        else
                            obj.parents(end + 1) = p.parents(j);
                            obj.weights(end + 1) = obj.weights(1 + i) * p.weights(1 + j);
                        end
                    end
                    obj.weights(1 + i) = [];
                    obj.parents(i) = [];
                else
                    i = i + 1;
                end
            end
        end
    end
    
end
