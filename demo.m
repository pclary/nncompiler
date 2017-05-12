%% Set up inputs
phase_sin = Input([-1 1], 'sin');
phase_cos = Input([-1 1], 'cos');
foot_z = Input([0 1], 'foot');

%% Math operations
z_target = 0.25 * phase_sin + 0 * phase_cos + 0.75;
z_err = foot_z - z_target;
gain = Clamp(1000 * phase_sin + 0 * phase_cos + 1000, [500 1500]);
control = z_err * gain;
gravity_comp = Rectify(300 * phase_sin + 0 * phase_cos);

%% Define output layer
foot_force_z_out = Output(control + gravity_comp);
phase_out = Output(Linear([], 1.5));
net = [foot_force_z_out phase_out];

%% Plot network
figure
net.plot();

%% Evaluate network at a point
net.eval([0.8 sin(0.1) cos(0.1)]);

%% Process network to prepare for compilation
net.normalize();
figure
net.plot();

%% Evaluate processed network at a point
% Note: input order switched during normalization
% Check order using [net.findInputs().name]
net.eval([sin(0.1) cos(0.1) 0.8]);

%% Compile the network into layers of weights
layers = net.compile();

%% Add redundant nodes
layers = padLayers(layers, 128);

%% Randomize weights slightly to break symmetry
inputRange = reshape([net.findInputs().scale], 2, 3)';
layers = perturbLayers(layers, 1e-4, inputRange);

%% Plot resulting surface
a = linspace(0, 1, 100);
b = linspace(0, 2*pi, 100);
[a, b] = meshgrid(a, b);
c = zeros(size(a));

invals = [sin(b(:))'; cos(b(:))'; a(:)'];
outvals = evalLayers(layers, invals);
c(:) = outvals(1, :);

figure
surf(a, b, c)
