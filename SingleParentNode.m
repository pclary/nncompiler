classdef SingleParentNode < Node
    
    methods
        function obj = SingleParentNode(parent, varargin)
            obj = obj@Node(parent, varargin{:});
            assert(numel(obj.parents) == 1);
        end
    end
    
end
