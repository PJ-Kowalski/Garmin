import Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application as App;
using Toybox.Time.Gregorian;
using Toybox.Sensor;
using Toybox.ActivityMonitor;
using Toybox.Math;
using Toybox.Activity;
using Toybox.Application.Storage;
using Toybox.SensorHistory;
using SunRiseSet as Sun;
using Toybox.UserProfile;
using Toybox.Communications;


class ExplorerLCDView extends WatchUi.WatchFace {

	//globar vars
	private const IMAGES = [$.Rez.Drawables.LauncherIcon] as Toybox.Lang.Array<Toybox.Lang.Symbol>;
	var drawable as Toybox.WatchUi.Bitmap;

	var latitude;
	var longitude;
	//icon variable declaration
	var iconXS =null;
	var mySettings = null;

	var colorBackgroung = App.getApp().getProperty("BackgroundColor");
	var colorForeground = App.getApp().getProperty("ForegroundColor");
	var colorIcon = App.getApp().getProperty("IconColor");
	var framesThicknes = App.getApp().getProperty("LinesTicknes");
	var framesColor = App.getApp().getProperty("FrameColor");
	//------------------------------------------------------------------------------------------

    function initialize() {
        WatchFace.initialize();

    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        iconXS= WatchUi.loadResource(Rez.Fonts.IconXS);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
		colorIcon = App.getApp().getProperty("IconColor");
		framesThicknes = App.getApp().getProperty("LinesTicknes");
		framesColor = App.getApp().getProperty("FrameColor");
	    var positionInfo = Activity.getActivityInfo().currentLocation;

				//check if position is avalible, else try to get position from staorage
				// latitude= 35.052666;
				// longitude = -78.878357;

				//Gliwice
				// latitude= 50.29761;
				// longitude =18.67658;
				if(positionInfo!=null){
					latitude= positionInfo.toDegrees()[0];
					longitude = positionInfo.toDegrees()[1];
					Storage.setValue("latitudeStored", latitude);
					Storage.setValue("longitudeStored", longitude);
				}
				else{
					latitude= Storage.getValue("latitudeStored");
					longitude = Storage.getValue("longitudeStored");
				}

    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        mySettings = System.getDeviceSettings();
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
        setClock(timeString);
        setDate();
        getActivitySensor();
        userProfile();
		setNotifi();
		//setAtmoSensor();

        // Call the parent onUpdate function to redraw the layout
		setStepsProgressBarr(dc);
        View.onUpdate(dc);
		setBattery(dc);
        setSunPosition(clockTime, dc);
        setIcons(dc);
        setFrames(dc);

    }



    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }
//--------------------------------------------------------------------------------------------------------Functions------------------------------------------------------------------------------------

	function setFrames(dc as Dc){
		dc.setPenWidth(framesThicknes);
        dc.setColor(framesColor, Graphics.COLOR_TRANSPARENT);
        //Hour Frame
        dc.drawRoundedRectangle(72, 95, 250, 67, 6);
        //Sun frame
        dc.drawRoundedRectangle(72, 55, 250, 107, 6);
		//icons
        dc.drawRoundedRectangle(17, 167, 250, 107, 6);
		//data field
        dc.drawRoundedRectangle(-10, 55, 77, 107, 6);
        //Date
        dc.drawRoundedRectangle(-10, -10, 222, 60, 6);
	}

    function setClock(time as Toybox.WatchUi.Text)  {
	    //var now = Time.now();
		var view = View.findDrawableById("Time") as Toybox.WatchUi.Text;
	    view.setColor(getApp().getProperty("ForegroundColor") as Toybox.Lang.Number);
	    view.setText(time);
    }

    function setDate(){
    	//Date
		var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		//var Day =today.day_of_week;
		var DayM=today.day;
		var Month =today.month;
		var Year =today.year;
		var dateFormat = "$1$ $2$ $3$";
		var dateString= Lang.format(dateFormat, [DayM, Month,Year]);

		var _date = View.findDrawableById("Date") as Toybox.WatchUi.Text;
		var _day = View.findDrawableById("DayNumber") as Toybox.WatchUi.Text;
		var _week = View.findDrawableById("WeekNumber") as Toybox.WatchUi.Text;
	    _date.setColor(getApp().getProperty("ForegroundColor") as Toybox.Lang.Number);
	    _date.setText(dateString);
	    _day.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
	    _day.setText("Day:"+SunRiseSet.DayOfYear().toString());
	    _week.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
	    _week.setText("Week:"+Sun.WeekOfTheYear().toString());
	    }

	function setSunPosition(clockTime, dc as Dc){
		//dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_LT_GRAY);
        //dc.setPenWidth(1);
        //dc.fillRoundedRectangle(80, 68, 160, 6, 1);
	//Sunrise sunset
		var timeZone=clockTime.timeZoneOffset/3600;
		var _sunRise = View.findDrawableById("SunRise") as Toybox.WatchUi.Text;
		var _sunSet = View.findDrawableById("SunSet") as Toybox.WatchUi.Text;
		var _dayLeft = View.findDrawableById("DayLeft") as Toybox.WatchUi.Text;
		var TimeToSunrise=null;
			if(latitude!=null){
				// var sunrise =Sun.sunRiseSet (latitude,  longitude,  90.5,  true, 2);
				// var sunset= Sun.sunRiseSet (latitude,  longitude,  90.5,  false, 2);
				var sunrise =Sun.sunRiseSet (latitude,  longitude,  90.5,  true, timeZone);
				var sunset= Sun.sunRiseSet (latitude,  longitude,  90.5,  false, timeZone);
				if(sunrise>24){
				sunrise=sunrise-24;}
				if(sunset>24){
				sunset=sunset-24;}
				TimeToSunrise = Sun.dayTimeLeft(clockTime, sunrise, sunset);
				_sunRise.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
				_sunRise.setText((Sun.HourFromDecimal(sunrise)).toString());
				_sunSet.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
				_sunSet.setText((Sun.HourFromDecimal(sunset)).toString());
				_dayLeft.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
				_dayLeft.setText(TimeToSunrise.toString());
				printSunIndicator(clockTime, dc,sunrise,sunset,160,8,80,66);
				}
	}

	function printSunIndicator(clockTime, dc as Dc,sunrise,sunset,lenght,height, x_start, y_start){
		//background rectangle
		dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_LT_GRAY);
        dc.setPenWidth(1);
        dc.fillRoundedRectangle(x_start, y_start, lenght, height, 2);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x_start, y_start, lenght, height, 2);
        //day rectangle position variable
        var rectangleDayX = (sunrise*lenght/24)+x_start;
		var rectangleDayWidtch = ((sunset-sunrise)*lenght/24);
		dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);
		dc.fillRectangle(rectangleDayX, y_start, rectangleDayWidtch, height);
		//Sun Indicator
		dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
		dc.fillRectangle(((clockTime.hour*lenght)/24)+x_start, 63, 6, 14);
		dc.setPenWidth(2);
		dc.setColor(getApp().getProperty("BackgroundColor") as Toybox.Lang.Number, Graphics.COLOR_BLUE);
		dc.drawRectangle(((clockTime.hour*lenght)/24)+x_start, 63, 6, 14);
	}

	function getActivitySensor(){
	//Sensors
		var info = ActivityMonitor.getInfo();
		var steps = info.steps;
		//var stepGoal = info.stepGoal;
		var calories = info.calories;
		//var floor=info.floorsClimbed;
		var activMinWeak =info.activeMinutesWeek.total;
		var _steps = View.findDrawableById("Steps") as Toybox.WatchUi.Text;
		var _calories = View.findDrawableById("Calories") as Toybox.WatchUi.Text;
		var _distance = View.findDrawableById("Field1") as Toybox.WatchUi.Text;
		var _activMinWeek = View.findDrawableById("Field2") as Toybox.WatchUi.Text;
		_steps.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
		_steps.setText(steps.toString());
		if(calories!=null){
			_calories.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
			_calories.setText(calories.toString());
		}
		if(info.distance!=null){
			var dist =info.distance/100000.0;
			_distance.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
			_distance.setText(dist.format("%0.01f").toString()+"km");
		}
		if(activMinWeak!=null){
			_activMinWeek.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
			_activMinWeek.setText(activMinWeak.toString());
		}
	}

	function setStepsProgressBarr(dc as Dc){
		var info = ActivityMonitor.getInfo();
		var steps = info.steps;
		var stepGoal = info.stepGoal;
		var percentOfDaylyGoal =100*steps/stepGoal;
		dc.setPenWidth(1);
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
		dc.drawRoundedRectangle(33, 172, 10, 18, 2);
		dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
		if(percentOfDaylyGoal>99){
			dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_PURPLE);
			dc.fillRectangle(34, 174, 8, 2);
		}
		if(percentOfDaylyGoal>80){
			dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_DK_GREEN);
			dc.fillRectangle(34, 177, 8, 2);
		}
		if(percentOfDaylyGoal>=75){
			dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_GREEN);
			dc.fillRectangle(34, 180, 8, 2);
		}
		if(percentOfDaylyGoal >50){
			dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);
			dc.fillRectangle(34, 183, 8, 2);
		}
		if(percentOfDaylyGoal >25){
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);
			dc.fillRectangle(34, 186, 8, 2);
		}

	}


	function userProfile(){
		var infoRHR = UserProfile.getProfile().averageRestingHeartRate;
		var _hr = View.findDrawableById("RestingHR") as Toybox.WatchUi.Text;
		//dc.setColor(colorForeground, Gfx.COLOR_TRANSPARENT);
		_hr.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
		if(infoRHR!=null){
		_hr.setText(infoRHR.toString());
		}
	}

	function setNotifi(){
		var messagesCount =mySettings.notificationCount;
		var alarmCount = mySettings.alarmCount;
		var _messagesCount = View.findDrawableById("NotyficationNumber") as Toybox.WatchUi.Text;
		var _alarmCount = View.findDrawableById("AlarmNumber") as Toybox.WatchUi.Text;
		_messagesCount.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
		_messagesCount.setText(messagesCount.toString());
		_alarmCount.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
		_alarmCount.setText(alarmCount.toString());
	}

	function setBattery(dc as Dc){
		var systemStatus= System.getSystemStats();
		var bateryStatus = systemStatus.battery.format("%2d");
		var _bateryStatus = View.findDrawableById("Battery") as Toybox.WatchUi.Text;
		_bateryStatus.setColor(getApp().getProperty("ForegroundColor2") as Toybox.Lang.Number);
		_bateryStatus.setText(bateryStatus.toString()+"%");
		dc.setPenWidth(1);
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
		dc.drawRoundedRectangle(49, 138, 12, 21, 1);
		dc.fillRectangle(52, 135, 6, 3);
		if(systemStatus.battery>=60){
			dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_GREEN);
			dc.fillRectangle(51, 140, 8, 5);
		}
		if(systemStatus.battery >40){
			dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);
			dc.fillRectangle(51, 146, 8, 5);
		}
		if(systemStatus.battery >20){
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);
			dc.fillRectangle(51, 152, 8, 5);
		}
	}

	function setAtmoSensor(){
		//var atmo = Activity.getActivityInfo();
		//var alt =atmo.altitude.toNumber();
		//var pressure =atmo.ambientPressure;
		//var _alt = View.findDrawableById("Height") as Text;
		//_alt.setColor(getApp().getProperty("ForegroundColor2") as Number);
		//if (_alt!=null){
		//_alt.setText(alt.toString()+"m");
		//}
		//var _pressure = View.findDrawableById("Preasure") as Text;
		//_pressure.setColor(getApp().getProperty("ForegroundColor2") as Number);
		//if (pressure!=null){
		//	pressure =(atmo.ambientPressure.toNumber())/100;
		//	_pressure.setText(pressure.toString()+" hPa");
		//}
	}

	function setIcons(dc as Dc){
		dc.setColor(colorIcon, Gfx.COLOR_TRANSPARENT);
		//calendar
		dc.drawText(185, 23, iconXS, "W", Gfx.TEXT_JUSTIFY_LEFT);
		//steps
		dc.drawText(116, 166, iconXS, "Q", Gfx.TEXT_JUSTIFY_LEFT);
		//distans
		dc.drawText(116, 196, iconXS, "O", Gfx.TEXT_JUSTIFY_LEFT);
		//calories
		dc.drawText(150, 166, iconXS, "X", Gfx.TEXT_JUSTIFY_LEFT);
		//active minutes
		dc.drawText(150, 196, iconXS, "o", Gfx.TEXT_JUSTIFY_LEFT);
		//Hart
		dc.drawText(113, 224, iconXS, "l", Gfx.TEXT_JUSTIFY_LEFT);
		//Notyfi
		dc.drawText(45, 82, iconXS, "t", Gfx.TEXT_JUSTIFY_LEFT);
		//Alam
		dc.drawText(45, 55, iconXS, "R", Gfx.TEXT_JUSTIFY_LEFT);
		//WiFi
		//System.println(mySettings.connectionInfo[:wifi].state.toString());
		//System.println(Toybox.System.ConnectionInfo.state);

		// if(mySettings.connectionInfo[:wifi].state==1){
		// 	dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
		// 	}
		// else if(mySettings.connectionInfo[:wifi].state==0){
		// dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
		// }
		// dc.drawText(45, 107, iconXS, "Ï", Gfx.TEXT_JUSTIFY_LEFT);

		//Bluetoth
		if(mySettings.phoneConnected){

			dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
			}
			else if(!mySettings.phoneConnected){
			dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
			}
		dc.drawText(45, 107, iconXS, "V", Gfx.TEXT_JUSTIFY_LEFT);
	}


    function setImage(){
    	var view = View.findDrawableById("LauncherIcon") as Toybox.WatchUi.Bitmap;

    }

    function getImage(index as Toybox.Lang.Number){
    	drawable = WatchUi.loadResource(IMAGES[index]) as Toybox.WatchUi.Bitmap;
    	return drawable;
    }

}
