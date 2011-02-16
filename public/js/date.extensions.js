/**
 * Returns a description of this past date in relative terms.
 * Takes an optional parameter (default: 0) setting the threshold in ms which
 * is considered "Just now".
 *
 * Examples, where new Date().toString() == "Mon Nov 23 2009 17:36:51 GMT-0500 (EST)":
 *
 * new Date().toRelativeTime()
 * --> 'Just now'
 *
 * new Date("Nov 21, 2009").toRelativeTime()
 * --> '2 days ago'
 *
 * // One second ago
 * new Date("Nov 23 2009 17:36:50 GMT-0500 (EST)").toRelativeTime()
 * --> '1 second ago'
 *
 * // One second ago, now setting a now_threshold to 5 seconds
 * new Date("Nov 23 2009 17:36:50 GMT-0500 (EST)").toRelativeTime(5000)
 * --> 'Just now'
 *
 */
Date.prototype.toRelativeTime = function(now_threshold) {
	var delta = new Date() - this;

	now_threshold = parseInt(now_threshold, 10);

	if (isNaN(now_threshold)) {
		now_threshold = 0;
	}

	if (delta <= now_threshold) {
		return 'Just now';
	}

	var units = null;
	var conversions = {
		millisecond: 1,
		// ms    -> ms
		second: 1000,
		// ms    -> sec
		minute: 60,
		// sec   -> min
		hour: 60,
		// min   -> hour
		day: 24,
		// hour  -> day
		month: 30,
		// day   -> month (roughly)
		year: 12 // month -> year
	};

	for (var key in conversions) {
		if (delta < conversions[key]) {
			break;
		} else {
			units = key; // keeps track of the selected key over the iteration
			delta = delta / conversions[key];
		}
	}

	// pluralize a unit when the difference is greater than 1.
	delta = Math.floor(delta);
	if (delta !== 1) {
		units += "s";
	}
	return [delta, units, "ago"].join(" ");
};

/*
 * Wraps up a common pattern used with this plugin whereby you take a String
 * representation of a Date, and want back a date object.
 */
Date.fromString = function(str) {
	return new Date(Date.parse(str));
};

/*
 * formatting stuff
 */
Date.prototype.formatDate = function(format)
{
	var date = this;
	if (!format)
	format = "MM/dd/yyyy";
	var month = date.getMonth() + 1;
	var year = date.getFullYear();
	format = format.replace("MM", month.toString().padL(2, "0"));
	if (format.indexOf("yyyy") > -1)
	format = format.replace("yyyy", year.toString());
	else if (format.indexOf("yy") > -1)
	format = format.replace("yy", year.toString().substr(2, 2));
	format = format.replace("dd", date.getDate().toString().padL(2, "0"));
	var hours = date.getHours();
	if (format.indexOf("t") > -1)
	{
		if (hours > 11)
		format = format.replace("t", "pm")
		else
		format = format.replace("t", "am")
	}
	if (format.indexOf("HH") > -1)
	format = format.replace("HH", hours.toString().padL(2, "0"));
	if (format.indexOf("hh") > -1) {
		if (hours > 12) hours - 12;
		if (hours == 0) hours = 12;
		format = format.replace("hh", hours.toString().padL(2, "0"));
	}
	if (format.indexOf("h") > -1) {
		if (hours > 12) hours -= 12;
		if (hours == 0) hours = 12;
		format = format.replace("h", hours.toString());
	}
	if (format.indexOf("mm") > -1)
	format = format.replace("mm", date.getMinutes().toString().padL(2, "0"));
	if (format.indexOf("ss") > -1)
	format = format.replace("ss", date.getSeconds().toString().padL(2, "0"));
	return format;
}
String.prototype.padL = function(length, padchar){
	var str = '' + this;
	while (str.length < length) {
		str = padchar + str;
	}
	return str;
}