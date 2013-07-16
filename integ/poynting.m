function S_scalar2d = poynting(varargin)

chkarg(nargin == 5 || nargin == 7, 'five or seven arguments are required.')

iarg = 0;
iarg = iarg + 1; polarization = varargin{iarg};
chkarg(istypesizeof(polarization, 'Axis'), '"argument %d should be "polarization" (instance of Axis).', iarg);

if istypesizeof(varargin{iarg+1}, 'Scalar3d')
	iarg = iarg + 1; Ep3d = varargin{iarg};
	chkarg(istypesizeof(Ep3d, 'Scalar3d'), '"argument %d should be "Ep3d" (instance of Scalar3d)."', iarg);

	iarg = iarg + 1; Eq3d = varargin{iarg};
	chkarg(istypesizeof(Eq3d, 'Scalar3d'), '"argument %d should be "Eq3d" (instance of Scalar3d)."', iarg);

	iarg = iarg + 1; Hp3d = varargin{iarg};
	chkarg(istypesizeof(Hp3d, 'Scalar3d'), '"argument %d should be "Hp3d" (instance of Scalar3d)."', iarg);

	iarg = iarg + 1; Hq3d = varargin{iarg};
	chkarg(istypesizeof(Hq3d, 'Scalar3d'), '"argument %d should be "Hq3d" (instance of Scalar3d)."', iarg);

	iarg = iarg + 1; normal_axis = varargin{iarg};
	chkarg(istypesizeof(normal_axis, 'Axis'), 'argument %d should be "normal_axis" (instance of Axis).', iarg);

	iarg = iarg + 1; intercept = varargin{iarg};
	chkarg(istypesizeof(intercept, 'real'), 'argument %d should be "intercept" (real).', iarg);
		
	grid3d = Ep3d.grid3d;
	chkarg(isequal(Eq3d.grid3d, grid3d) && isequal(Hp3d.grid3d, grid3d) && isequal(Hq3d.grid3d, grid3d), ... 
		'instances of Scalar3d do not have same grid3d.');
	
	Ep2d = slice_scalar3d(Ep3d, normal_axis, intercept);
	Eq2d = slice_scalar3d(Eq3d, normal_axis, intercept);
	Hp2d = slice_scalar3d(Hp3d, normal_axis, intercept);
	Hq2d = slice_scalar3d(Hq3d, normal_axis, intercept);

	grid2d = Ep2d.grid2d;
else
	iarg = iarg + 1; Ep2d = varargin{iarg};
	chkarg(istypesizeof(Ep2d, 'Scalar2d'), '"argument %d should be "Ep2d" (instance of Scalar2d)."', iarg);

	iarg = iarg + 1; Eq2d = varargin{iarg};
	chkarg(istypesizeof(Eq2d, 'Scalar2d'), '"argument %d should be "Eq2d" (instance of Scalar2d)."', iarg);

	iarg = iarg + 1; Hp2d = varargin{iarg};
	chkarg(istypesizeof(Hp2d, 'Scalar2d'), '"argument %d should be "Hp2d" (instance of Scalar2d)."', iarg);

	iarg = iarg + 1; Hq2d = varargin{iarg};
	chkarg(istypesizeof(Hq2d, 'Scalar2d'), '"argument %d should be "Hq2d" (instance of Scalar2d)."', iarg);
	
	
	grid2d = Ep2d.grid2d;
	intercept = Ep2d.intercept;
	chkarg(Eq2d.intercept==intercept && Hp2d.intercept==intercept && Hq2d.intercept==intercept, ...
		'instances of Scalar2d do not have same intercept.');
	chkarg(isequal(Eq2d.grid2d, grid2d) && isequal(Hp2d.grid2d, grid2d) && isequal(Hq2d.grid2d, grid2d), ... 
		'instances of Scalar2d do not have same grid2d.');
end

% Interpolate fields at face centers of unit cells.
pi = grid2d.l{Dir.h,GT.dual};
qi = grid2d.l{Dir.v,GT.dual};
[PI, QI] = ndgrid(pi, qi);

ep = interp_Scalar2d(Ep2d, grid2d, PI, QI);
eq = interp_Scalar2d(Eq2d, grid2d, PI, QI);
hp = interp_Scalar2d(Hp2d, grid2d, PI, QI);
hq = interp_Scalar2d(Hq2d, grid2d, PI, QI);

array = real(ep .* conj(hq) - eq .* conj(hp)) / 2;

% Attach extra points.
for d = Dir.elems
	array = attach_extra_S(array, d, grid2d);
end

osc = Ep2d.osc;
physQ = PhysQ.S;
gt_array = [GT.dual, GT.dual];  % face centers

% Resume here.
% The attached values to array should be the same as the ones inside the array
% if BC is not periodic.
S_scalar2d = Scalar2d(array, grid2d, gt_array, osc, physQ, [physQ.symbol, '_', char(polarization)], intercept);


function array = interp_Scalar2d(scalar2d, grid2d, PI, QI)
chkarg(istypesizeof(PI, 'complex', grid2d.N), '"PI" should be %d-by-%d array with complex numbers.');
chkarg(istypesizeof(QI, 'complex', grid2d.N), '"QI" should be %d-by-%d array with complex numbers.');

l = grid2d.lall(Dir.elems + Dir.count*subsindex(scalar2d.gt_array));

[P, Q] = ndgrid(l{:});
array = interpn(P, Q, scalar2d.array, PI, QI);


function array = attach_extra_S(array, d, grid2d)
ind_n = {':', ':'};
ind_p = {':', ':'};
bc_d = grid2d.bc(d);
if bc_d == BC.p
	ind_n{d} = grid2d.N(d);
	ind_p{d} = 1;
else  % bc_d == BC.e or BC.m
	ind_n{d} = 1;
	ind_p{d} = grid2d.N(d);	
end
array = cat(int(d), array(ind_n{:}), array, array(ind_p{:}));  % Bloch phases in S are ignored due to conj(H)
