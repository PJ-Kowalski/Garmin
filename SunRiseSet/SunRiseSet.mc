using Toybox.System;
using Toybox.Lang;
using Toybox.Time.Gregorian;
using Toybox.Time;
using Toybox.Math;
module SunRiseSet {

function sunRiseSet ( latitude,  longitude,  zenith,  riseSet, localOffset)
	{
	//  riseSet :1=sunrise, 0 sunset
	//  localOffset=time shift to UTC
	//	latitude, longitude:   location for sunrise/sunset
	//	zenith:                Sun's zenith for sunrise/sunset
	//	  offical      = 90 degrees 50'
	//	  civil        = 96 degrees
	//	  nautical     = 102 degrees
	//	  astronomical = 108 degrees
	var D2R = Math.PI / 180;
	var R2D = 180 / Math.PI;
	var dayOfYear=DayOfYear();
	//convert the longitude to hour value and calculate an approximate time
	var lngHour = longitude / 15;
	//if rising or set time is desired
	var t;

		if(riseSet){
			t = dayOfYear + ((6 - lngHour) / 24);}
		else{
			t = dayOfYear + ((18 - lngHour) / 24);}
	//calculate the Sun's mean anomaly
	var M = (0.9856 * t) - 3.289;
	//calculate the Sun's true longitude
	var L = M + (1.916 * Math.sin(M*D2R)) + (0.020*Math.sin(2*M*D2R)) + 282.634;
		if (L > 360) {
	        L = L - 360;}
	    else if (L < 0) {
	        L = L + 360;}
	//calculate the Sun's right ascension
	var RA =R2D* Math.atan(0.91764 * Math.tan(L*D2R));
		if (RA > 360) {
	        RA = RA - 360;}
	    else if (RA < 0) {
	        RA = RA + 360;}
	//right ascension value needs to be in the same quadrant as L
	var Lquadrant  = (Math.floor( L/90)) * 90;
	var	RAquadrant = (Math.floor(RA/90)) * 90;
		RA = RA + (Lquadrant - RAquadrant);
	//right ascension value needs to be converted into hours
	RA = RA / 15;
	//calculate the Sun's declination
	var sinDec = 0.39782 * Math.sin(L*D2R);
	var	cosDec = Math.cos(Math.asin(sinDec));
	//calculate the Sun's local hour angle
	var	cosH = (Math.cos(zenith*D2R)-(sinDec*Math.sin(latitude*D2R))) / (cosDec*Math.cos(latitude*D2R));

		if (cosH>1){
		  System.print("the sun never rises on this location (on the specified date)");}
		if (cosH<-1){
		  System.print("the sun never sets on this location (on the specified date)");}
	//finish calculating H and convert into hours
	var H;
		 if (riseSet) {
	        H = 360 - R2D * Math.acos(cosH);}
	     else {
	        H = R2D * Math.acos(cosH);}

		H = H / 15;
	//calculate local mean time of rising/setting
	var T = H+RA-(0.06571*t)-6.622;
	//adjust back to UTC
	    var UT = T - lngHour;
	//convert UT value to local time zone of latitude/longitude
	var localT = UT + localOffset;
	  if (localT > 24) {
	        localT = localT - 24;}
	    else if (localT < 0) {
	        localT = localT + 24;}
	return localT;
}

function HourFromDecimal(decimalData){
//convert from decimal data to Hour:minutes format
	var hour =Math.floor(decimalData);
	var minutesDecimal=decimalData-hour ;
	var minutes=minutesDecimal*60;
	//added for south globe
	if(hour>23){hour=hour-24;}
	var timeFormat = "$1$:$2$";
	var dateString= Lang.format(timeFormat, [hour.format("%02d"),minutes.format("%02d")]);
	return dateString;
}

function WeekOfTheYear(){
		var dateS = Gregorian.info(Time.now(), Time.FORMAT_SHORT); //data today
		var dayOfYear =DayOfYear(); //day of the year
		var dayOfWeek = dateS.day_of_week; // day number mon=1 tue =2 ...

		var options = {
         :year   => dateS.year,
         :month  => 1,
         :day    => 1,
         :hour   => 0
     	 };
     var momentOfCurrentYear =Gregorian.moment(options);

     var firstDayInYear = Gregorian.info(momentOfCurrentYear,Time.FORMAT_SHORT); // first day of current year
	 var yearFirstDayOfWeek = firstDayInYear.day_of_week;

	 var week= ((dayOfYear + 6) / 7);
	 if (dayOfWeek < yearFirstDayOfWeek)
	 {
	 week = week+1;
	 }
	 return (week); //-1 hotfix for 2021
}

function DayOfYear(){
	var dayOfYear=0;
	var normalYear =[31,28,31,30,31,30,31,31,30,31,30,31];
	var leapYear =[31,29,31,30,31,30,31,31,30,31,30,31];
	var dateS = Gregorian.info(Time.now(), Time.FORMAT_SHORT); //data today
	var day =dateS.day;
	var month =dateS.month;
	var year =dateS.year;

	if((year%4==0 && year%100!=0) or year%400==0)
	{
		for(var i=0;i<month-1;i++)
		{
		dayOfYear=dayOfYear+leapYear[i];
		}
		dayOfYear = dayOfYear+day;
	}
	else
	{
		for(var i=0;i<month-1;i++)
		{
		dayOfYear=dayOfYear+normalYear[i];
		}
		dayOfYear = dayOfYear+day;
	}
	return(dayOfYear);
	}

	//function return time left to sunrise, and time to sunset
	function dayTimeLeft(currentTime, sunrise, sunset)
	{

		var hours = currentTime.hour.toFloat();
		var minutes =currentTime.min.toFloat();
		var minutesDecimal =minutes/60;
		var decimalTime =hours+minutesDecimal;
		var timeTo=null;
		if(decimalTime<sunrise){
		timeTo=HourFromDecimal(sunrise-decimalTime);
		}
		else if(decimalTime>sunset){
		timeTo="--:--  ";}
		else if(decimalTime>sunrise){
		timeTo=HourFromDecimal(sunset-decimalTime);
		}
		return timeTo;
	}

}
