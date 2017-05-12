function layers = padLayers(layers, n)
% Pad all hidden layers to size n, while adding network redundancy

for i = numel(layers)-1:-1:1
    % Determine the number of times each existing unit is duplicated
    nunits = size(layers{i}, 1);
    nnew = n - nunits;
    nreps = floor(nnew / nunits);
    copies = nreps * ones(nunits, 1);
    a = randsample(nunits, nnew - nreps * nunits);
    copies(a) = copies(a) + 1;
    
    % Duplicate each unit the requisite number of times
    for j = 1:nunits
        layers{i} = [layers{i}; repmat(layers{i}(j, :), copies(j), 1)];
        layers{i + 1}(:, 1 + j) = layers{i + 1}(:, 1 + j) / (copies(j) + 1);
        layers{i + 1} = [layers{i + 1} repmat(layers{i + 1}(:, 1 + j), 1, copies(j))];
    end
end
