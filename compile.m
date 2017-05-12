function layers = compile(outputs)

outputs.replace();
while ~outputs.minimal()
    outputs.reduce();
end

