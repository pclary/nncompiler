function layers = perturbLayers(layers, std, inputRange)

range = inputRange;

for i = 1:numel(layers)
    % Get typical magnitude of last layer's output
    lastmag = mean(abs(range), 2);
    
    % Compute value range for this layer's output, before applying tanh
    a = layers{i} .* [1 range(:, 1)'];
    b = layers{i} .* [1 range(:, 2)'];
    linrange = [sum(min(a, b), 2) sum(max(a, b), 2)];
    
    % Get typical magnitude of this layer's output
    mag = mean(abs(linrange), 2);
    
    % Add random perturbations to layer weights, scaled using magnitudes
    pert = std * mag .* randn(size(layers{i})) ./ [1 lastmag'];
    layers{i} = layers{i} + pert;
    
    % Get post-tanh range for this layer
    range = tanh(linrange);
end
