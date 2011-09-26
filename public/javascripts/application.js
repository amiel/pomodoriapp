$(document).ready(function() {

    // $('.timeago').timeago();



    $('.pomodoros .start.time').each(function(index) {
        var start_element = $(this),
            start_time = start_element.attr('title'),
            start_date = new Date(Date.parse(start_time)),
            end_date = new Date(+start_date + (25 * 60 * 1000)),
            left_element = start_element.parent().find('.left');

        // console.log(start_element, start_time, start_date, end_date);

        var timer;

        var update = function() {

            var now = new Date,
                seconds_left = (end_date - now) / 1000,
                minutes_left = Math.floor(seconds_left / 60),
                minute_seconds_left = Math.floor(seconds_left % 60);

            if (seconds_left < 0) {
                clearInterval(timer);
                left_element.text("FINISHED");
            } else {
                left_element.text(minutes_left + ":" + minute_seconds_left + " left");
            }
        };

        timer = setInterval(update, 1000);
        update();

    });
});
