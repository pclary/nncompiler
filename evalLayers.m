function out = evalLayers(layers, in)
% Evaluate the network using the given input vector

out = in;

for i = 1:numel(layers) - 1
    out = tanh(layers{i} * [ones(1, size(out, 2)); out]);
end

out = layers{end} * [ones(1, size(out, 2)); out];
