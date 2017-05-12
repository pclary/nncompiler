classdef Node < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    
    properties
        parents(1, :) Node
        name(1, 1) string
        
        % Used for internal operations
        value(1, 1) double
        flag(1, 1) logical
        new(1, :) Node
        children(1, :) Node
        scale(1, 2) double
        depth(1, 1) double
    end
    
    
    methods
        function obj = Node(parents, varargin)
            obj.value = NaN;
            obj.flag = false;
            obj.parents = parents;
            obj.scale = [NaN NaN];
            obj.depth = -inf;
            if nargin > 1
                obj.name = varargin{1};
            end
        end
        
        
        function cpObj = copyGraph(obj)
            obj.setAll('new', Node.empty());
            cpObj = obj.copy();
            obj.setAll('new', Node.empty());
        end
        
        
        function res = plus(obj1, obj2)
            if isa(obj1, 'Node') && isa(obj2, 'Node')
                res = Linear([obj1 obj2], [0 1 1]);
            elseif isa(obj1, 'Node') && isa(obj2, 'double')
                res = Linear(obj1, [obj2 1]);
            elseif isa(obj1, 'double') && isa(obj2, 'Node')
                res = Linear(obj2, [obj1 1]);
            end
        end
        
        
        function res = minus(obj1, obj2)
            if isa(obj1, 'Node') && isa(obj2, 'Node')
                res = Linear([obj1 obj2], [0 1 -1]);
            elseif isa(obj1, 'Node') && isa(obj2, 'double')
                res = Linear(obj1, [-obj2 1]);
            elseif isa(obj1, 'double') && isa(obj2, 'Node')
                res = Linear(obj2, [obj1 -1]);
            end
        end
        
        
        function res = mtimes(obj1, obj2)
            if isa(obj1, 'Node') && isa(obj2, 'Node')
                res = Multiply([obj1 obj2]);
            elseif isa(obj1, 'Node') && isa(obj2, 'double')
                res = Linear(obj1, [0 obj2]);
            elseif isa(obj1, 'double') && isa(obj2, 'Node')
                res = Linear(obj2, [0 obj1]);
            end
        end
    end
    
    
    methods (Sealed)
        function simplify(obj)
            for i = 1:numel(obj)
                obj(i).parents.simplify();
                obj(i).simplifyElement();
            end
        end
        
        
        function res = eq(H1, H2)
            res = eq@handle(H1, H2);
        end
        
        
        function computeScale(obj)
            obj.setAll('flag', false);
            obj.computeScaleImpl();
        end
        
        
        function computeDepth(obj)
            obj.setAll('depth', -inf);
            obj.computeDepthImpl(0);
        end
        
        
        function replaceNonlinear(obj)
            obj.computeScale();
            obj.findChildren();
            obj.setAll('flag', false);
            obj.replaceNonlinearImpl();
        end
        
        
        function nodes = enumerate(obj)
            obj.setAll('flag', false);
            nodes = obj.enumerateImpl();
        end
        
        
        function plot(obj)
            nodes = obj.enumerate();
            A = zeros(numel(nodes));
            for i = 1:numel(nodes)
                for p = nodes(i).parents
                    j = find(nodes == p, 1);
                    A(i, j) = 1;
                end
            end
            
            nodetypes = strings(size(nodes));
            for i = 1:numel(nodetypes)
                nodetypes(i) = class(nodes(i)) + string(i);
            end
            
            names = [nodes.name];
            names(names == "") = nodetypes(names == "");
            
%             obj.computeScale();
%             sc = reshape([nodes.scale], 2, numel(nodes));
%             names = names + ", " + "[" + string(sc(1, :)) + " " + string(sc(2, :)) + "]";
            
%             obj.eval([0.8 sin(0.1) cos(0.1)]);
%             names = names + ", " + fillmissing(string([nodes.value]), 'constant', "NaN");
            
%             obj.computeDepth();
%             names = names + ", " + [nodes.depth];
            
            G = digraph(A, cellstr(names));
            plot(G)
        end
    end
    
    
    methods (Access = protected)
        function inputs = findInputsImpl(obj)
            inputs = Input.empty();
            for i = 1:numel(obj.parents)
                if ~obj.parents(i).flag
                    inputs = [inputs obj.parents(i).findInputsImpl()];
                end
            end
            obj.flag = true;
        end
        
        
        function simplifyElement(~)
        end
        
        
        function [headObj, tailObj] = replaceNonlinearElement(obj)
            headObj = obj;
            tailObj = obj;
        end
    end
    
    
    methods (Access = protected, Sealed)
        function cpObj = copyElement(obj)
            % Error when using copy() instead of copyGraph()
            if ~any(arrayfun(@(s)strcmp(s.name, 'Node.copyGraph'), dbstack()))
                error('Use copyGraph() instead of copy() to duplicate part of a graph');
            end
            
            if ~isempty(obj.new)
                cpObj = obj.new;
                return
            end
            
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            obj.new = cpObj;
            
            for i = 1:numel(obj.parents)
                cpObj.parents(i) = cpObj.parents(i).copy();
            end
        end
        
        
        function setAll(obj, field, value)
            for i = 1:numel(obj)
                obj(i).(field) = value;
                obj(i).parents.setAll(field, value);
            end
        end
        
        
        function values = evalImpl(obj)
            % Evaluate an array of nodes
            values = zeros(size(obj));
            for i = 1:numel(obj)
                % If there is no memoized value, calculate it and set the flag
                if ~obj(i).flag
                    obj(i).value = obj(i).evalElement();
                    obj(i).flag = true;
                end
                values(i) = obj(i).value;
            end
        end
        
        
        function findChildren(obj)
            obj.setAll('children', Node.empty());
            obj.setAll('flag', false);
            obj.findChildrenImpl();
        end
        
        
        function findChildrenImpl(obj)
            for i = 1:numel(obj)
                if ~obj(i).flag
                    for j = 1:numel(obj(i).parents)
                        if ~any(obj(i).parents(j).children == obj(i))
                            obj(i).parents(j).children(end + 1) = obj(i);
                        end
                    end
                    obj(i).flag = true;
                end
                obj(i).parents.findChildrenImpl();
            end
        end
        
        
        function nodes = enumerateImpl(obj)
            nodes = Node.empty();
            for i = 1:numel(obj)
                if ~obj(i).flag
                    nodes = [nodes obj(i) obj(i).parents.enumerateImpl()];
                    obj(i).flag = true;
                end
            end
        end
        
        
        function computeScaleImpl(obj)
            for i = 1:numel(obj)
                if ~obj(i).flag
                    obj(i).parents.computeScaleImpl();
                    obj(i).computeScaleElement();
                    obj(i).flag = true;
                end
            end
        end
        
        
        function computeDepthImpl(obj, depth)
            for i = 1:numel(obj)
                obj(i).depth = max(obj(i).depth, depth + obj(i).getCompiledHeight());
                obj(i).parents.computeDepthImpl(obj(i).depth);
            end
        end
        
        
        function replaceNonlinearImpl(obj)
            for i = 1:numel(obj)
                [headObj, tailObj] = obj(i).replaceNonlinearElement();
                obj(i).replaceNode(headObj, tailObj);
                obj(i).parents.replaceNonlinearImpl();
            end
        end
        
        
        function headObj = getPassthrough(obj)
            m = mean(obj.scale);
            s = 10 * diff(obj.scale) / 2;
            headObj = Linear(Tanh(Linear(obj, [-m/s 1/s])), [m s]);
            headObj.computeDepthImpl(obj.depth);
        end
        
        
        function normalizeChildDepthImpl(obj)
            for i = 1:numel(obj)
                if ~obj(i).flag
                    obj(i).normalizeChildDepthElement();
                    obj(i).children.normalizeChildDepthImpl();
                    obj(i).flag = true;
                end
            end
        end
        
        
        function normalizeChildDepthElement(obj)
            head = obj;
            for d = obj.depth-2:-1:min(min([obj.children.depth]))
                head = head.getPassthrough();
                obj.children([obj.children.depth] == d).replaceParent(obj, head);
            end
        end
        
        
        function replaceNode(obj, headObj, tailObj)
            if ~(headObj == obj && tailObj == obj)
                obj.parents.replaceChild(obj, tailObj);
                obj.children.replaceParent(obj, headObj);
            end
        end
        
        
        function replaceParent(obj, old, new)
            for i = 1:numel(obj)
                obj(i).parents(obj(i).parents == old) = new;
            end
        end
        
        
        function replaceChild(obj, old, new)
            for i = 1:numel(obj)
                obj(i).children(obj(i).children == old) = [];
                obj(i).children = [obj(i).children new];
            end
        end
    end
    
    
    methods (Abstract, Access = protected)
        value = evalElement(obj)
        computeScaleElement(obj)
        height = getCompiledHeight(obj)
    end
    
end
