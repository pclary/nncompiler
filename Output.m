classdef Output < SingleParentNode
    
    methods
        function obj = Output(parent, varargin)
            obj = obj@SingleParentNode(parent, varargin{:});
        end
        
        
        function outvals = eval(obj, invals)
            % Get the input nodes
            inputs = obj.findInputs();
            
            % Set the input node values
            for i = 1:numel(inputs)
                inputs(i).value = invals(i);
            end
            
            % Compute the value of each output node by traversing the graph
            obj.setAll('flag', false);
            outvals = obj.evalImpl();
        end
        
        
        function inputs = findInputs(obj)
            % Clear internal temp variables
            obj.setAll('flag', false)
            
            % Get an array of all of the input nodes that are ancestors of any
            % of the output nodes
            inputs = Input.empty();
            for i = 1:numel(obj)
                inputs = [inputs; obj(i).findInputsImpl()];
            end
        end
        
        
        function normalize(obj)
            % Replace nonlinear nodes with tanh nodes and simplify linearities
            obj.replaceNonlinear();
            obj.simplify();
            
            % Set all inputs to a consistent depth
            obj.computeDepth();
            obj.computeScale();
            obj.findChildren();
            inputs = obj.findInputs();
            maxdepth = max([inputs.depth]);
            for i = 1:numel(inputs)
                for j = 1:maxdepth - inputs(i).depth
                    headObj = inputs(i).getPassthrough();
                    replaceNode(inputs(i), headObj, inputs(i));
                end
            end
            
            % Add passthrough nodes until all children are at a consistent depth
            obj.normalizeChildDepth();
            
            % Simplify linearities
            obj.simplify();
        end
        
        
        function layers = compile(obj)
            % Make sure network is normalized
            obj.normalize();
            nodes = obj.enumerate();
            
            % Get type of each node
            types = strings(size(nodes));
            for i = 1:numel(types)
                types(i) = class(nodes(i));
            end
            
            % Find number of layers (not including input)
            obj.computeDepth();
            depths = [nodes.depth];
            nlayers = max(depths) - 1;
            
            % Find node indices for each layer
            layerinds = cell(nlayers + 1, 1);
            layerinds{1} = find(depths == 1 & types == "Output");
            for i = 2:nlayers
                layerinds{i} = find(depths == i & types == "Tanh");
            end
            layerinds{end} = find(depths == nlayers + 1 & types == "Input");
            
            % Initialize layer weight matrices
            layers = cell(nlayers, 1);
            for i = 1:nlayers
                layers{i} = zeros(numel(layerinds{i}), 1 + numel(layerinds{i + 1}));
                
                inds = layerinds{i};
                for j = 1:numel(inds)
                    % Get parents and weights of the linear node feeding into this node
                    p = nodes(inds(j)).parents.parents;
                    w = nodes(inds(j)).parents.weights;
                    
                    % Set the bias for this node
                    layers{i}(j, 1) = w(1);
                    
                    % Set the weights for this node
                    for k = 1:numel(p)
                        % Find the index into the previous layer corresponding to this parent
                        a = find(layerinds{i + 1} == find(nodes == p(k), 1), 1);
                        layers{i}(j, 1 + a) = w(1 + k);
                    end
                end
            end
            
            % Flip layer order to go from input to output
            layers = layers(end:-1:1);
        end
        
        
        function normalizeChildDepth(obj)
            inputs = obj.findInputs();
            obj.findChildren();
            obj.setAll('flag', false);
            inputs.normalizeChildDepthImpl();
        end
    end
    
    
    methods (Access = protected)
        function value = evalElement(obj)
            % Passthrough
            value = obj.parents.evalImpl();
        end
        
        
        function computeScaleElement(obj)
            obj.scale = obj.parents.scale;
        end
        
        
        function height = getCompiledHeight(~)
            height = 1;
        end
    end
    
end
