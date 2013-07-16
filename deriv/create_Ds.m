function Ds_cell = create_Ds(s, ge, dl_cell, gridnd)

chkarg(istypesizeof(s, 'Sign'), '"s" should be instance of Sign.');  % Ds = Df (or Df) when s == Sign.p (or Sign.n)
chkarg(istypesizeof(ge, 'GT'), '"ge" should be instance of GT.');  % ge: grid type for the E-field
chkarg(istypesizeof(gridnd, 'Grid2d') || istypesizeof(gridnd, 'Grid3d'), '"gridnd" should be instance of Grid2d or Grid3d.');

is3D = true;
v = Axis.x;
if istypesizeof(gridnd, 'Grid2d')
	is3D = false;
	v = Dir.h;
end

%% Get the shape.
N = gridnd.N;

%% Get the relevant derivative matrices.
g = GT.elems(s);  % curl, divergence, gradient all uses dl_dual for forward difference and dl_prim for backward difference

if is3D
	[dx, dy, dz] = ndgrid(dl_cell{Axis.x,g}, dl_cell{Axis.y,g}, dl_cell{Axis.z,g});
	dl = {dx, dy, dz};
else
	[dh, dv] = ndgrid(dl_cell{Dir.h,g}, dl_cell{Dir.v,g});
	dl = {dh, dv};
end

bc = gridnd.bc;

% Basic setup of Df and Db.  Here, masking of f1 to zero is not performed.  It
% is performed by outside this function; that way the symmetry of the matrix can
% be more easily achieved.  The symmetry for the cases where f1 = 2 should be
% achieved separately, though.
Ds_cell = cell(1, v.count);
if s == Sign.p  % Ds == Df
	for w = v.elems
		f1 = 1;

		if bc(w) == BC.p
			fg = exp(-1i * gridnd.kBloch(w) * gridnd.L(w));
		else  % ghost point BC is BC.e if ge == GT.prim; BC.m if ge == GT.dual
			fg = 0;
		end

		Ds_cell{w} = create_Dw(w, N, f1, fg);
	end
else  % Ds == Db
	for w = v.elems
		if (ge == GT.prim && bc(w) == BC.m) || (ge == GT.dual && bc(w) == BC.e)
			f1 = 2;  % symmetry of operator for this case is not implemented yet
		else
			f1 = 1;
		end

		if bc(w) == BC.p
			fg = exp(-1i * gridnd.kBloch(w) * gridnd.L(w));
		else  % bc(w) == BC.e or BC.m
			fg = 0;  % f1 = 1 or 2 takes care of the ghost point
		end

		Ds_cell{w} = create_Dw(w, N, f1, fg);
		Ds_cell{w} = -Ds_cell{w}';  % conjugate transpose rather than transpose (hence nonsymmetry for kBloch ~= 0)
	end
end

my_diag = @(z) spdiags(z(:), 0, numel(z), numel(z));

for w = v.elems
	Ds_cell{w} = my_diag(dl{w}.^-1) * Ds_cell{w};
end
