clear all; close all; clear classes; clc;

%% Set flags.
isnew = true;
inspect_only = false;

%% Create shapes.
a = 420;  % lattice constant
t = 0.6*a;  % slab thickness
r = 0.29*a;  % hole radius
h = sqrt(3)/2*a;  % distance between rows of holes

ad = 20;  % divider for a
td = 10;  % divider for t
dd = 10;  % divider for d = 2*r

slab = Box([-5.5*a, 5.5*a; -3.5*h, 3.5*h; -t/2, t/2]);
slab_yn = Box([-5.5*a, 5.5*a; -3.5*h, -0.5*h; -t/2, t/2]);
slab_yp = Box([-5.5*a, 5.5*a; 0.5*h, 3.5*h; -t/2, t/2]);

hole = CircularCylinder(Axis.z, [0 0 0], r, t);

hole_yn_array = periodize_shape(hole, {[a 0 0], [a/2 h 0], [0 0 t]}, slab_yn);
hole_yp_array = periodize_shape(hole, {[a 0 0], [a/2 h 0], [0 0 t]}, slab_yp);
hole_array = [hole_yn_array, hole_yp_array];

%% Solve the system.
if isnew
gray = [0.5 0.5 0.5];  % [r g b]
	withuniformgrid = true;
	[E, H, obj_array, err] = maxwell_run(1e-9, 1550, ...
		{'vacuum', 'white', 1.0}, [-5.5*a, 5.5*a; -3.5*h, 3.5*h; -3*t, 3*t], [11*a/220, 7*h/71, t/td], BC.p, [2*a 0 t], withuniformgrid, ...
		{'Palik/Si', gray}, slab, ...
		{'vacuum', 'white', 1.0}, periodize_shape(hole, {[a 0 0], [a/2 h 0], [0 0 t]}, slab_yn), ...
		{'vacuum', 'white', 1.0}, periodize_shape(hole, {[a 0 0], [a/2 h 0], [0 0 t]}, slab_yp), ...
		PointSrc(Axis.y, [0, 0, 0]), inspect_only);

	save(mfilename, 'E', 'H', 'obj_array');
else
	load(mfilename);
end

%% Visualize the solution.
if ~inspect_only
	figure;
	opts.cscale = 5e-3;
	opts.withobj = false;
	visall(E{Axis.y}, obj_array, opts);
end