Pusher.log = function(message) {
    if (window.console && window.console.log) window.console.log(message);
};

$(document).ready(function() {


    var pusher = new Pusher('322ec20ec6e1389ccd71');
    var pomodoro_channel = pusher.subscribe('pomodoro');

    var pomodoros = $('#pomodoros');


    pomodoros.find('li').each(function() {
        var li = $(this),
            left_element = li.find('.left');

        var start_time,
            start_date,
            end_date,

            status,
            timer;


        var calculate_dates = function() {
            start_time = li.attr('data-started-at');
            finish_time = li.attr('data-finish-at');
            status = li.attr('class');
            start_date = new Date(Date.parse(start_time));
            finish_date = new Date(Date.parse(finish_time));
            end_date = (function(s) {
                return {
                    started: function(start_date)  { return new Date(+start_date + (25 * 60 * 1000)); },
                    break: function(finish_date) { return new Date(+finish_date + (5 * 60 * 1000)); }
                }[s];
            })(status)(start_date);


            console.log("calculate_dates status:", status, "start_date:", start_date, "finish_date:", finish_date);
        };


        var update = function() {
            var now = new Date,
                seconds_left = (end_date - now) / 1000,
                minutes_left = Math.floor(seconds_left / 60),
                minute_seconds_left = Math.floor(seconds_left % 60);

            if (seconds_left < 0) {
                stop_timer();
                left_element.text("");
            } else {
                left_element.text(minutes_left + ":" + minute_seconds_left + " left");
            }
        };

        var start_timer = function() {
            calculate_dates();
            timer = setInterval(update, 1000);
            update();
        };

        var stop_timer = function() {
            clearInterval(timer);
        };

        var restart_timer = function() {
            stop_timer();
            start_timer();
        };

        start_timer();

        var update_element = function(infos) {
            status = infos.status;

            var element = pomodoros.find('li[title="' + infos.name + '"]');
            // TODO: Use weld to create/render them pomodoros.

            element.find('.description').text(infos.description);
            element.attr('data-started-at', infos.started_at);
            element.attr('data-finish-at', infos.finish_at);
            element.find('.status').text(infos.friendly_status);
            element.attr('class', status);
        };

        pomodoro_channel.bind('start', function(infos) {
            update_element(infos);
            restart_timer();
        });

        pomodoro_channel.bind('end', function(infos) {
            update_element(infos);
            restart_timer();
        });

        pomodoro_channel.bind('break_end', function(infos) {
            update_element(infos);
            stop_timer();
            left_element.text("");
        });
    });

});
