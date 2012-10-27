classdef Grid3d < handle
    % Grid has all the information related to the 3D Yee grid.
	% It does not have physical quantities dependent on frequencies, e.g.,
	% omega, eps, mu, and PML s-factors.

    properties (SetAccess = immutable)
		comp  % [Grid1d_x, Grid1d_y, Grid1d_z]
	end
	
	% There is an advantage of having the following dependent properties over
	% having corresponding methods.  For example, if bc is implemented as a
	% method with zero argument, it is called as grid3d.bc().  When a method
	% does not take any argument, MATLAB actually allows to call it as if it is
	% a property, i.e., grid3d.bc.  However, then the component of bc cannot be
	% accessed through the usual indexing as grid3d.bc(Axis.x, Sign.n), because
	% the method bc() takes no argument.  By implementing bc as a dependent
	% property, both grid3d.bc and grid3d.bc(Axis.x, Sign.n) work.
	properties (Dependent, SetAccess = immutable)
		unit  % instance of PhysUnit
		unitvalue  %  unit value of length
        l  % {x_prim, x_dual; y_prim, y_dual; z_prim, z_dual}
		lg  %  {x_prim with ghost, x_dual with ghost; y_prim with ghost, y_dual with ghost; z_prim with ghost, z_dual with ghost};
		lall  %  {x_prim with ghost, x_dual with extra vertices; y_prim with ghost, y_dual with extra vertices; z_prim with ghost, z_dual with extra vertices};
        dl  % {diff(x_prim), diff(x_dual); diff(y_prim), diff(y_dual); diff(z_prim), diff(z_dual)}
        bc  % [bc_xn, bc_xp; bc_yn, bc_yp; bc_zn, bc_zp]
        N  % [Nx, Ny, Nz]: # of grid cells in the x, y, z directions
		Ntot  % Nx*Ny*Nz
		L  % [Lx, Ly, Lz]: size of the domain
        Npml  % [Npml_xn, Npml_xp; Npml_yn, Npml_yp; Npml_zn, Npml_zp]: # of primary grid cells inside PML
		lpml  % [lpml_xn, lpml_xp; lpml_yn, lpml_yp; lpml_zn, lpml_zp]: locations of PML interfaces
		Lpml  % [Lpml_xn, Lpml_xp; Lpml_yn, Lpml_yp; Lpml_zn, Lpml_zp]: thicknesses of PML
		center  % [center_x, center_y, center_z]: center of grid wiouth PML
	end
	
	properties (Dependent, SetAccess = private)
		kBloch
	end
        
    methods
        function this = Grid3d(unit, lprim_cell, Npml, bc)
			% Check and store arguments.
			chkarg(istypesizeof(unit, 'PhysUnit'), '"unit" should be instance of PhysUnit.');
			
			chkarg(istypesizeof(lprim_cell, 'realcell', [1, Axis.count], [1 0]), ...
				'"lprim_cell" should be length-%d row cell array whose each element is row vector with real elements.', Axis.count);
			
			if nargin < 3  % no Npml
				Npml = 0;
			end
			chkarg(istypeof(Npml, 'int'), 'element of "Npml" should be integral.');
			chkarg(isexpandable2mat(Npml, Axis.count, Sign.count), ...
				'"Npml" should be scalar, length-%d vector, or %d-by-%d matrix.', Axis.count, Axis.count, Sign.count);
			Npml = expand2mat(Npml, Axis.count, Sign.count);
			            
			if nargin < 4  % no bc
				bc = BC.Ht0;
			end
			chkarg(istypeof(bc, 'BC'), 'element of "bc" should be integral.');
			chkarg(isexpandable2mat(bc, Axis.count, Sign.count), ...
				'"bc" should be scalar, length-%d vector, or %d-by-%d matrix.', Axis.count, Axis.count, Sign.count);
			bc = expand2mat(bc, Axis.count, Sign.count);
			
			% Set comp.
			this.comp = Grid1d.empty();
			for w = Axis.elems
				this.comp(w) = Grid1d(w, unit, lprim_cell{w}, Npml(w,:), bc(w,:));
			end
		end
		
		function unit = get.unit(this)
			unit = this.comp(Axis.x).unit;
		end
		
		function unit = get.unitvalue(this)
			unit = this.comp(Axis.x).unitvalue;
		end
		
		function l = get.l(this)
			l = cell(Axis.count, GK.count);
			for w = Axis.elems
				for g = GK.elems
					l{w, g} = this.comp(w).l{g};
				end
			end
		end
			
		function lg = get.lg(this)
			lg = cell(Axis.count, GK.count);
			for w = Axis.elems
				for g = GK.elems
					lg{w, g} = this.comp(w).lg{g};
				end
			end
		end

		function lall = get.lall(this)
			lall = cell(Axis.count, GK.count);
			for w = Axis.elems
				for g = GK.elems
					lall{w, g} = this.comp(w).lall{g};
				end
			end
		end

		function dl = get.dl(this)
			dl = cell(Axis.count, GK.count);
			for w = Axis.elems
				for g = GK.elems
					dl{w, g} = this.comp(w).dl{g};
				end
			end
		end
		
		function bc = get.bc(this)
			bc = BC.empty();
			for w = Axis.elems
				bc(w,:) = this.comp(w).bc;
			end
		end
		
		function N = get.N(this)
			N = NaN(1, Axis.count);
			for w = Axis.elems
				N(w) = this.comp(w).N;
			end
		end
		
		function Ntot = get.Ntot(this)
			Ntot = prod(this.N);
		end
		
		function L = get.L(this)
			L = NaN(1, Axis.count);
			for w = Axis.elems
				L(w) = this.comp(w).L;
			end
		end
		
		function Npml = get.Npml(this)
			Npml = NaN(Axis.count, Sign.count);
			for w = Axis.elems
				Npml(w,:) = this.comp(w).Npml;
			end
		end
		
		function lpml = get.lpml(this)
			lpml = NaN(Axis.count, Sign.count);
			for w = Axis.elems
				lpml(w,:) = this.comp(w).lpml;
			end
		end
		
		function Lpml = get.Lpml(this)
			Lpml = NaN(Axis.count, Sign.count);
			for w = Axis.elems
				Lpml(w,:) = this.comp(w).Lpml;
			end
		end
		
		function center = get.center(this)
			center = NaN(1, Axis.count);
			for w = Axis.elems
				center(w) = this.comp(w).center;
			end
		end
		
		function set_kBloch(this, plane_src)
			for w = Axis.elems
				this.comp(w).set_kBloch(plane_src);
			end
		end
		
		function kBloch = get.kBloch(this)
			kBloch = NaN(1, Axis.count);
			for w = Axis.elems
				kBloch(w) = this.comp(w).kBloch;
			end
		end
		
		function truth = contains(this, point)
			chkarg(istypesizeof(point, 'real', [0, Axis.count]), ...
				'"point" should be matrix with %d columns with real elements.', Axis.count);
			n = size(point, 1);
			truth = true(n, 1);
			for w = Axis.elems
				truth = truth & this.comp(w).contains(point(:,w));
			end
		end
		
		function bound_plot = bound_plot(this, withpml)
			bound_plot = NaN(Axis.count, Sign.count);
			for w = Axis.elems
				bound_plot(w,:) = this.comp(w).bound_plot(withpml);
			end
		end
		
		function lplot_cell = lplot(this, gk, withpml)
			chkarg(istypesizeof(gk, 'GK') , '"gk" should be empty or instance of GK');
			chkarg(istypesizeof(withpml, 'logical'), '"withpml" should be logical.');
			
			lplot_cell = cell(1, Axis.count);
			for w = Axis.elems
				lplot_cell{w} = this.comp(w).lplot(gk, withpml);
			end
		end		
	end
end