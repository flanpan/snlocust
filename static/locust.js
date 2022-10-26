$(window).ready(function() {
    function createWS() {
        let ws = new WebSocket(window.option.wsurl)
        ws.onopen = ()=> console.log('ws connected.')
        ws.onclose = (ev)=> {
            console.log('ws closed.', ev)
            setTimeout(()=>{
                console.log('ws reconnect...')
                window.ws = createWS()
            }, 3000)
        }
        ws.onerror = (err)=> console.log('ws error.', ev)
        ws.onmessage = (ev)=> {
            let data = JSON.parse(ev.data)
            switch(data.type) {
                case 'log':
                    return console.log(data.body)
                case 'console':
                    return console[data.body.func].apply(console, data.body.args)
            }
        }
        return ws
    }
    window.ws = createWS()
    $('#script').val(window.option.script)

    if($("#first_id").length > 0) {
        $("#first_id").focus().select();
    }
});

function appearStopped() {
    $(".box_stop").hide();
    $("a.new_test").show();
    $("a.edit_test").hide();
    $(".user_count").hide();
}

$("#box_stop a.stop-button").click(function(event) {
    event.preventDefault();
    $.get($(this).attr("href"));
    $("body").attr("class", "stopped");
    appearStopped()
});

$("#box_stop a.reset-button").click(function(event) {
    event.preventDefault();
    $.get($(this).attr("href"));
});

$("#new_test").click(function(event) {
    event.preventDefault();
    $("#start").show();
    $("#first_id").focus().select();
});

$(".edit_test").click(function(event) {
    event.preventDefault();
    $("#edit").show();
    $("#new_user_count").focus().select();
});

$(".close_link").click(function(event) {
    event.preventDefault();
    $(this).parent().parent().hide();
});

$("ul.tabs").tabs("div.panes > div").on("onClick", function(event) {
    if (event.target == $(".chart-tab-link")[0]) {
        // trigger resizing of charts
        rpsChart.resize();
        responseTimeChart.resize();
        usersChart.resize();
    }
    if (event.target == $(".counter-tab-link")[0]) {
        for(var name in counterChart) {
            counterChart[name].resize()
        }
    }
});

var stats_tpl = $('#stats-template');
var errors_tpl = $('#errors-template');
var exceptions_tpl = $('#exceptions-template');
var workers_tpl = $('#worker-template');

function setScript(script) {
    script = script || "";
    $('#script_top').text(script);
}

$('#swarm_form').submit(function(event) {
    event.preventDefault();
    $("body").attr("class", "hatching");
    $("#start").fadeOut();
    $("#status").fadeIn();
    $(".box_running").fadeIn();
    $("a.new_test").fadeOut();
    $("a.edit_test").fadeIn();
    $(".user_count").fadeIn();
    $.post($(this).attr("action"), $(this).serialize(),
        function(response) {
            if (response.success) {
                setScript(response.script);
            }
        }
    );
});

$('#edit_form').submit(function(event) {
    event.preventDefault();
    $.post($(this).attr("action"), $(this).serialize(),
        function(response) {
            if (response.success) {
                $("body").attr("class", "hatching");
                $("#edit").fadeOut();
                setScript(response.script);
            }
        }
    );
});

var sortBy = function(field, reverse, primer){
    reverse = (reverse) ? -1 : 1;
    return function(a,b){
        a = a[field];
        b = b[field];
       if (typeof(primer) != 'undefined'){
           a = primer(a);
           b = primer(b);
       }
       if (a<b) return reverse * -1;
       if (a>b) return reverse * 1;
       return 0;
    }
}

// Sorting by column
var alternate = false; //used by jqote2.min.js
var sortAttribute = "name";
var WorkerSortAttribute = "id";
var desc = false;
var WorkerDesc = false;
var report;

function renderTable(report) {
    report.stats = report.stats instanceof Array ? report.stats : []
    report.errors = report.errors instanceof Array ? report.errors : []
    var totalRow = report.stats.pop();
    totalRow.is_aggregated = true;
    var sortedStats = (report.stats).sort(sortBy(sortAttribute, desc));
    sortedStats.push(totalRow);
    $('#stats tbody').empty();
    $('#errors tbody').empty();

    window.alternate = false;
    $('#stats tbody').jqoteapp(stats_tpl, sortedStats);

    window.alternate = false;
    $('#errors tbody').jqoteapp(errors_tpl, (report.errors).sort(sortBy(sortAttribute, desc)));

    $("#total_rps").html(Math.round(report.total_rps*100)/100);
    $("#fail_ratio").html(Math.round(report.fail_ratio*100));
    $("#status_text").html(report.state);
    $("#userCount").html(report.user_count);
}

function renderWorkerTable(report) {
    if (report.workers) {
        var workers = (report.workers).sort(sortBy(WorkerSortAttribute, WorkerDesc));
        $("#workers tbody").empty();
        window.alternate = false;
        $("#workers tbody").jqoteapp(workers_tpl, workers);
        $("#workerCount").html(workers.length);
    }
}


$("#stats .stats_label").click(function(event) {
    event.preventDefault();
    sortAttribute = $(this).attr("data-sortkey");
    desc = !desc;
    renderTable(window.report);
});

$("#workers .stats_label").click(function(event) {
    event.preventDefault();
    WorkerSortAttribute = $(this).attr("data-sortkey");
    WorkerDesc = !WorkerDesc;
    renderWorkerTable(window.report);
});

// init charts
var rpsChart = new LocustLineChart($(".charts-container"), "Total Requests per Second", ["RPS", "Failures/s"], "reqs/s", ['#00ca5a', '#ff6d6d']);
var responseTimeChart = new LocustLineChart($(".charts-container"), "Response Times (ms)", ["Median Response Time", "95% percentile"], "ms");
var usersChart = new LocustLineChart($(".charts-container"), "Number of Users", ["Users"], "users");
var counterChart = {}

function updateStats() {
    $.get('./stats/requests', function (report) {
        window.report = report;

        renderTable(report);
        renderWorkerTable(report);

        if (report.state !== "stopped"){
            // get total stats row
            var total = report.stats[report.stats.length-1];
            // update charts
            rpsChart.addValue([total.current_rps, total.current_fail_per_sec]);
            responseTimeChart.addValue([report.current_response_time_percentile_50, report.current_response_time_percentile_95]);
            usersChart.addValue([report.user_count]);

            // update counter
            var counter = report.counter
            if(counter) {
                for(var name in counter) {
                    if(!counterChart[name])
                        counterChart[name] = new LocustLineChart($(".counter-container"), name, [name], name);
                    counterChart[name].addValue([counter[name]])
                }
            }
        } else {
            appearStopped();
        }

        setTimeout(updateStats, 2000);
    });
}
updateStats();

function updateExceptions() {
    $.get('./exceptions', function (data) {
        data.exceptions = data.exceptions instanceof Array ? data.exceptions : []
        $('#exceptions tbody').empty();
        $('#exceptions tbody').jqoteapp(exceptions_tpl, data.exceptions);
        setTimeout(updateExceptions, 5000);
    });
}
updateExceptions();
