/* STA402: Final Project
   Author: Karen Gaither
   Purpose: This project looks at the incomes in each neighborhood
	 	    of Manhattan to determine if it has an effect on the 
	        prices of Airbnbs in those neighborhoods.
*/

%let wd = M:\STA402\Final Project;
%let bnb = AB_NYC_2019.csv;
%let income = manhattan_incomes.csv;
%let stamps = foodstamp_rates.csv;

* Output to an rtf file;
ods rtf file = "&wd\proj_output.rtf"
	style = journal bodytitle; 

* Full Airbnb data;
data listings;
	infile "&wd\&bnb" firstobs=2 dsd;
	input id name :$55. host_id host_name :$35. borough :$20. neighborhood :$25. 
		latitude longitude room_type :$16. price min_nights reviews last_review :$10.
		monthly_reviews host_listings availability;
run;
proc print data=listings (obs=10);
run;

* Drops Airbnb listings outside Manhattan and only keeps
   relevant variables;
data listings_manhat;
	set listings;
	if borough ne "Manhattan" then delete;
	keep name borough neighborhood room_type price;
run;
proc print data=listings_manhat (obs=10);
run;

* Median income in Manhattan neighborhoods data;
data income;
	infile "&wd\&income" firstobs=2 dsd;
	input neighborhood :$30. income;
run;
proc print data=income (obs=10);
run;

* Percentage of people on food stamps in each Manhattan neighborhood;
data foodstamps;
	infile "&wd\&stamps" firstobs=2 dsd;
	input neighborhood :$30. stamps_rate;
run;

* Merges the datasets using an inner join so it only keeps 
   neighborhoods that are in both;
proc sql;
create table airbnb_half as
	select listings_manhat.name, listings_manhat.neighborhood,
			listings_manhat.price, listings_manhat.room_type, income.income
	from listings_manhat, income
	where listings_manhat.neighborhood = income.neighborhood;
quit;

* Uses another inner join to merge the food stamps data;
proc sql;
create table airbnb as
	select airbnb_half.name, airbnb_half.neighborhood, airbnb_half.price,
		   airbnb_half.room_type, airbnb_half.income, foodstamps.stamps_rate
	from airbnb_half, foodstamps
	where airbnb_half.neighborhood = foodstamps.neighborhood;
quit;
proc print data=airbnb (obs=10);
run;

* Scatter plots of price vs. income of the different room types;
proc sgplot data=airbnb;
	scatter x=income y=price;
	where room_type = "Private room";
run;
proc sgplot data=airbnb;
	scatter x=income y=price;
	where room_type = "Shared room";
run;
proc sgplot data=airbnb;
	scatter x=income y=price;
	where room_type = "Entire home/apt";
run;

* Looks at the mean price in each neighborhood;
proc means data=airbnb;
	class neighborhood;
	var price;
	types neighborhood;
	output out=avg_prices mean=avg_price min=min_price max=max_price;
run;

* Merges the average prices data with the income data to see 
   the values side by side;
data averages;
	merge avg_prices income foodstamps;
	by neighborhood;
	drop _type_ _freq_;
run;

proc sort data=averages;
	by avg_price;
run;
proc print data=averages;
run;


* Linear model with room type and income;
proc glm data=airbnb plots(maxpoints=20000)=diagnostics;
	class room_type;
	model price = room_type income / solution;
	output out=resid p=yhat r=residual;
run;
quit;

* "Residuals vs. Fitted Values Plot";
proc sgplot data = resid;
	scatter x=yhat y=residual;
run;

* Log transformation to deal with nonconstant variance;
data airbnb;
	set airbnb;
	log_price = log(price);
run;

* Fitted model with the log transformation of price;
proc glm data = airbnb plots(maxpoints=20000)=diagnostics;
	class room_type;
	model log_price = room_type income / solution;
	output out = logresid p=yhat r=residual;
run;
quit;

* Residuals plot with log transformation;
proc sgplot data = logresid;
	scatter x=yhat y=residual;
run;


* Scatterplot of food stamps rate vs. Airbnb price;
proc sgplot data=airbnb;
	scatter x=price y=stamps_rate;
run;

 * Tests if the food stamps rate is a significant predictor of price;
proc glm data=airbnb;
	model price = stamps_rate / solution;
run;
quit;



ods rtf close;








