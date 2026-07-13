% Model of a simple district heating network									
% picked up from "Integrated Optimal Power Flow For Electric Power And Heat in a Microgrid"									
function model = heatmodel									
									
% pipe								
model.pipe = [								
	% from_node	to_node	length(m)	diameter(m)	roughness	conductivity	Mmin	Mmax
	1	2	3500	0.8	0.0005	0.12 	0	Inf
	2	3	1750	0.8	0.0005	0.12 	0	Inf
	3	4	1750	0.8	0.0005	0.12 	0	Inf
	2	5	1750	0.8	0.0005	0.12 	0	Inf
	3	6	750	0.8	0.0005	0.12 	0	Inf
	4	7	1750	0.8	0.0005	0.12 	0	Inf
	4	8	750	0.8	0.0005	0.12 	0	Inf
];								

% node									
model.node = [									
	% node	load(kJ)	Tsmin	Tsmax	Trmin	Trmax	Prmin	Prmax	Plmin
	1	0	110	120	60	80	-Inf	Inf	50000
	2	0	110	120	60	80	-Inf	Inf	50000
	3	0	110	120	60	80	-Inf	Inf	50000
	4	0	110	120	60	80	-Inf	Inf	50000
	5	8	110	120	60	80	-Inf	Inf	50000
	6	32	110	120	60	80	-Inf	Inf	50000
	7	39.2	110	120	60	80	-Inf	Inf	50000
	8	8	110	120	60	80	-Inf	Inf	50000
];									

% combined heat and power									
model.chp = [									
	% node	Pmin	Pmax	Hmin	Hmax	efficiency	Mmin	Mmax	Gen
	1.00 	0.00 	Inf	0.00 	Inf	1.00 	0.00 	Inf	3 
];									
									
% pump						
model.pump = [						
	% node	Pmin	Pmax	efficiency	Mmin	Mmax
	1	0	2	0.8	0	Inf
];						
									
model.chpcost = [									
	% startup	shutdown	order	p1	p2	p3			
	0	0	1	1	0	0			
];									
									
model.pumpcost = [									
	% startup	shutdown	order	p1	p2	p3			
	0	0	1	1	0	0			
];									
									
model.load = [									
	30								
	30								
	28.06451613								
	29.03225806								
	29.03225806								
	29.03225806								
	28.06451613								
	27.09677419								
	25.16129032								
	24.19354839								
	23.22580645								
	22.25806452								
	21.29032258								
	21.29032258								
	21.29032258								
	22.25806452								
	23.22580645								
	24.19354839								
	24.19354839								
	24.19354839								
	25.16129032								
	26.12903226								
	27.09677419								
	27.09677419								
];									
									
% outdoor temperature									
model.t0 = [									
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
	-10								
];									
									
model.water_c = 4.2e3; % (J*kg^(-1)*K^(-1))									
model.water_dens = 1e3; %(kg*m^(-3))									
model.base	=	1e6;	%	base	value	of	power	(W)	
