Pusher.log = function(message) {
    if (window.console && window.console.log) window.console.log(message);
};



var Updater = (function() {
    var functions = [];
    var add = function(to_add) {
        functions.push(to_add);
    };

    var remove = function(to_remove) {
        functions = $.map(functions, function(e) { if (e != to_remove) return e; });
    };

    var update = function() {
        $.each(functions, function() {
            this();
        });
    };

    var timer = setInterval(update, 1000);

    return {
        add: add,
        remove: remove
    }
})();


$(document).ready(function() {

    var pomodoros = $('#pomodoros');


    pomodoros.find('li').each(function() {
        var li = $(this),
            left_element = li.find('time');

        var start_time,
            start_date,
            end_date,

            status = li.attr('class');


        var calculate_dates = function() {
            start_time = li.attr('data-started-at');
            finish_time = li.attr('data-finish-at');
            start_date = new Date(Date.parse(start_time));
            finish_date = new Date(Date.parse(finish_time));
            end_date = (function(s) {
                return({
                    started: function(start_date)  { return new Date(+start_date + (25 * 60 * 1000)); },
                    break: function(finish_date) { return new Date(+finish_date + (5 * 60 * 1000)); },
                    finished: function(finish_date) { return finish_date; }
                }[s] || function() { console.log("calculate_dates: no end_date function for", s); });
            })(status)(start_date);


            console.log("calculate_dates for", li.attr('title'), "status:", status, "start_date:", start_date, "finish_date:", finish_date);
        };


        var update = function() {
            var now = new Date,
                seconds_left = (end_date - now) / 1000,
                minutes_left = Math.floor(seconds_left / 60).toString(),
                minute_seconds_left = Math.floor(seconds_left % 60).toString();

            // console.log("UPDATE", seconds_left, minutes_left, minute_seconds_left, li.attr('title'), status);

            if (minute_seconds_left.length == 1) {
                minute_seconds_left = "0" + minute_seconds_left;
            }

            if (seconds_left < 0 || isNaN(seconds_left)) {
                stop_timer();
                left_element.text("");
            } else {
                left_element.text(minutes_left + ":" + minute_seconds_left);
            }
        };

        var start_timer = function() {
            calculate_dates();
            Updater.add(update);
        };

        var stop_timer = function() {
            Updater.remove(update);
            left_element.text('');
        };

        var restart_timer = function() {
            stop_timer();
            start_timer();
        };

        li.bind('stop_timer', stop_timer);
        li.bind('restart_timer', restart_timer);

        li.bind('update_status', function() {
            status = li.attr('class');
        });

        start_timer();
    });

    (function() {


        var pusher = new Pusher('322ec20ec6e1389ccd71');
        var pomodoro_channel = pusher.subscribe('pomodoro');

        var get_element = function(infos) {
            return pomodoros.find('li[title="' + infos.name + '"]');
        };

        var update_element = function(element, infos) {
            // TODO: Use weld to create/render them pomodoros.

            element.find('.description').text(infos.description);
            element.attr('data-started-at', infos.started_at);
            element.attr('data-finish-at', infos.finish_at);
            element.find('.status').text(infos.friendly_status);
            element.attr('class', infos.status);

            element.trigger('update_status');
        };

        pomodoro_channel.bind('start', function(infos) {
            var element = get_element(infos)
            update_element(element, infos);
            element.trigger('restart_timer');
        });

        pomodoro_channel.bind('end', function(infos) {
            var element = get_element(infos)
            update_element(element, infos);
            element.trigger('restart_timer');
        });

        pomodoro_channel.bind('break_end', function(infos) {
            var element = get_element(infos)
            update_element(element, infos);
            element.trigger('stop_timer');
        });
    })();
});
