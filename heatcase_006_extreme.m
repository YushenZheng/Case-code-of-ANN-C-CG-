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
% 	4	7	1750	0.8	0.0005	0.12 	0	Inf
% 	4	8	750	0.8	0.0005	0.12 	0	Inf
];								

% node									
model.node = [									
	% node	load(kJ)	Tsmin	Tsmax	Trmin	Trmax	Prmin	Prmax	Plmin
	1	0	110	120	60	80	-Inf	Inf	50000
	2	0	110	120	60	80	-Inf	Inf	50000
	3	0	110	120	60	80	-Inf	Inf	50000
	4	47.2	110	120	60	80	-Inf	Inf	50000
	5	8	110	120	60	80	-Inf	Inf	50000
	6	32	110	120	60	80	-Inf	Inf	50000
% 	7	39.2	110	120	60	80	-Inf	Inf	50000
% 	8	8	110	120	60	80	-Inf	Inf	50000
];									

% combined heat and power									
model.chp = [									
	% node	Pmin	Pmax	Hmin	Hmax	efficiency	Mmin	Mmax	Gen
	1 	0.00 	Inf	0.00 	Inf	1 	0.00 	Inf	3 
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
50
50
48.06451613
49.03225806
49.03225806
49.03225806
48.06451613
47.09677419
45.16129032
44.19354839
43.22580645
46.66666667
48.33333333
49.16666667
50
53.33333333
56.66666667
60
63.33333333
65
65.83333333
66.66666667
66.66666667
70
];									
									
% outdoor temperature									
model.t0 = [									
-10
-10
-8.838709678
-9.419354836
-9.419354836
-9.419354836
-8.838709678
-8.258064514
-7.096774192
-6.516129034
-5.93548387
-8
-9
-9.5
-10
-12
-14
-16
-18
-19
-19.5
-20
-20
-22
];									
									
model.water_c = 4.2e3; % (J*kg^(-1)*K^(-1))									
model.water_dens = 1e3; %(kg*m^(-3))									
model.base	=	1e6;	%	base	value	of	power	(W)	
