/*********************************************
 * OPL 12.9.0.0 Model
 * Author: mnmz4
 * Creation Date: 25 баев„ 2020 at 12:29:11
 *********************************************/

int n =...; // n cities 

int Cash = ...; // the Cash for the Trip 

int min_days_of_travle = ...;

int max_days_of_travle = ...;

int minDaysInCity = ...;

int CarRentPerDay = ...;

int GasPrice = ...;

int timeRunCplexInMinute = ...;

range citiesRange = 1..n; // this is  the range of i and j 

range U_Range = 2..n;// for the range of U

range temp = 1..5;


//
string city_Name[citiesRange] =...;
float Travel_Time[citiesRange][citiesRange] = ...;
float Travel_Distance[citiesRange][citiesRange] = ...;
int CostPerDayAllCities[citiesRange] = ...;
int MaxTimeInCityAllCities[citiesRange] = ...;
int PreferenceToVisit[temp][citiesRange] = ...;
// this is struct for vertex
tuple CityData{
	string CityName;
  	int CostPerDay;
  	int MaxTimeInCity;
  	int PreferenceTo[temp];
}
// this is struct for edge
tuple edge { 
 	int i;
 	int j; 
}
// create a set of edges
setof(edge) edges ={<i,j> | i,j in citiesRange : i != j};

// distance of every edge, variable d in the mathmatical model
float distance[edges];

// driving time of every edge, variable t in the mathmatical model
float travel[edges]; //travel Time

// cost time of every edge, variable c in the mathmatical model
float Cost_of_travel[edges];

//array of the cities with their respective variables
CityData cities[citiesRange];

// pre-processing. Init of variables and Cplex configuration
execute {
	 cplex.startalg = 1;  
	 
	 cplex.subalg = 0; //default
	 
	 cplex.tilim = 60*timeRunCplexInMinute; //computation time limit (timeRunCplexInMinute mins)
	 
	 cplex.threads = 4;
	// giving values to city variables
	for(var i in citiesRange) {
		cities[i].CityName = city_Name[i];
		cities[i].CostPerDay = CostPerDayAllCities[i];
		cities[i].MaxTimeInCity = MaxTimeInCityAllCities[i];
		for(var j in temp)
			cities[i].PreferenceTo[j] = PreferenceToVisit[j][i];
	}
	
	// giving values to edge variables
	for (var e in edges) {
		distance[e] =1 + Math.round(Travel_Distance[e.i][e.j]);
		travel[e] = 1 + Math.round(Travel_Time[e.i][e.j]);
		Cost_of_travel[e] = (1 + Math.round(travel[e]/24))*CarRentPerDay + (1 + Math.round(distance[e]/14))*GasPrice;
	}
}
// desicion variable
// binary values for edge taken or not
dvar boolean x[edges];
// the order of visit for city i
dvar int+ u[2..n];
// the time spent in city i
dvar int+ timeInCity[1..n];
// the total money spent in city i (timeInCity * costPerDay)
dvar int+ costInCity[1..n];
// expressions of Objective function
dexpr float TotalDistance = sum(e in edges) distance[e]*x[e];
//
dexpr float TotalCost =sum(e in edges) ((Cost_of_travel[e]*x[e])) + sum(i in citiesRange) costInCity[i];
// all Time trivel
dexpr float TotalTime =sum(e in edges) ((travel[e]*x[e])/24) + sum(i in citiesRange) timeInCity[i];
// what we need of Objective function
minimize TotalDistance;

subject to {
  
	//for the First Constraint in the math model
	forall(j in citiesRange)
	  edge_in:
	  sum (i in citiesRange : i!=j) x[<i,j>] == 1;
	 //for the second Constraint in the math model
	 forall(i in citiesRange)
	   edge_out:
	   sum (j in citiesRange : i!=j) x[<i,j>] == 1;
	   
	 //for the second Constraint in the math model
	 forall(i in citiesRange: i>1,j in citiesRange : j>1 && j!=i)
	   subtour:
	   u[i]-u[j] + x[<i,j>]*(n) <=n-1;
	   
	// making the order value strat from 2 until n
	forall(i in citiesRange : i>1)
	    ordering_values:
	    2 <= u[i] <= n;
	    
	forall(i in citiesRange)
	   days_in_city:
	   minDaysInCity <= timeInCity[i] <= cities[i].MaxTimeInCity;
	       
	total_trip_time:
	 min_days_of_travle <= TotalTime <= max_days_of_travle; 
	 
	//making sure some cities are not visited at certain times of the year
	forall(i in citiesRange : i>1)
	  forall(j in temp)
	    ordering_preference:
	    	cities[i].PreferenceTo[j] != u[i];
	    	
	//
	forall(i in citiesRange)
	   cost_in_city:
	   costInCity[i] == timeInCity[i]*cities[i].CostPerDay;
	
	//
	 total_trip_cost:
	 TotalCost <= Cash;
	  
}
// Post-processing is hust tell CPLEX that to do somthing after solving the problem

// the range of 0<= u[i]<=n-2
execute{
	
	var ofile = new IloOplOutputFile("trip_order.txt");
	
		ofile.writeln("-->", cities[1].CityName);
		for(var i in U_Range) {	
			for (var j in U_Range){
				if(i == u[j]){
					ofile.writeln(",",cities[j].CityName);
					break;		
				}			
			}
		}
		ofile.writeln(",",cities[1].CityName);	
		ofile.close();
			
}

main {
  thisOplModel.generate();
  var start_time = cplex.getCplexTime();
  cplex.solve();
  var ofile = new IloOplOutputFile("theSolutions.txt");
  
  ofile.writeln("********************Parameters********************" );
  ofile.writeln("Number of cities: ", thisOplModel.n );
  ofile.writeln("Budget: ", thisOplModel.Cash);
  ofile.writeln("Min days for travle: ", thisOplModel.min_days_of_travle); 
  ofile.writeln("Max days for travle: ", thisOplModel.max_days_of_travle); 
  ofile.writeln("Minimum days to spend in each city: ", thisOplModel.minDaysInCity);
  ofile.writeln("Time given to solver for solution: ", thisOplModel.timeRunCplexInMinute, " Mins\n");
  
  
  
  if(cplex.status == 1 | cplex.status == 11){
    
  	ofile.writeln ( "********************Solution********************\n");
  	ofile.writeln("Total distance of route: ", thisOplModel.TotalDistance, " KM");
  	ofile.write("Total cost: ",thisOplModel.TotalCost, " Shekel\n");
  	ofile.writeln("Total days of trip: ", thisOplModel.TotalTime, " Days");
  	if(cplex.status == 11)
  		ofile.writeln ("Elapsed time is: Max time reached (", thisOplModel.timeRunCplexInMinute, "Mins)\n");
  	else
  		ofile.writeln ("Elapsed time is: ",cplex.getCplexTime() - start_time, " Sec\n");
  	
  	ofile.write(thisOplModel.cities[1].CityName,"(",thisOplModel.timeInCity[1],")","(",thisOplModel.costInCity[1],")", "--> ");
  	var cnt = 1;
		for(var i in thisOplModel.U_Range) {	
			for (var j in thisOplModel.U_Range){
				if(i == thisOplModel.u[j]){
				  if(cnt % 5 == 0){
				  	ofile.writeln("");
     			}				  	
					ofile.write(thisOplModel.cities[j].CityName,"(",thisOplModel.timeInCity[j],")","(",thisOplModel.costInCity[j],")", "--> ");
					cnt++;
					break;		
				}			
			}
		}
	ofile.writeln(thisOplModel.cities[1].CityName, "\n");
  	
  	ofile.writeln(thisOplModel.printSolution());
  	
  	
   	ofile.writeln ( "********************External Data********************");
   	ofile.writeln(thisOplModel.printExternalData());
   	ofile.writeln ( "********************Internal Data********************");
   	ofile.writeln(thisOplModel.printInternalData());
	ofile.close();
 }
 else {
   	ofile.writeln ( "********************Solution********************\n");
   	ofile.writeln("NO SOLUTION FOUND\n");
  	ofile.close();
  	
   	ofile = new IloOplOutputFile("problem.txt");
   	ofile.writeln ("Elapsed time is: ",cplex.getCplexTime() - start_time);
   	ofile.writeln ( "********************Relaxation********************");
  	ofile.writeln(thisOplModel.printRelaxation());
  	ofile.writeln ( "********************Conflict**********************");
  	ofile.writeln(thisOplModel.printConflict());
   	ofile.writeln ( "********************External Data********************");
   	ofile.writeln(thisOplModel.printExternalData());
   	ofile.writeln ( "********************Internal Data********************");
   	ofile.writeln(thisOplModel.printInternalData());
   	ofile.close();
 }  	
  thisOplModel.postProcess();
}

