var WebClient = function (io) {
  this.nodes = {};
  this.ids = {};
  this.streams = {};
  this.count = 0;
  this.detailTimer = false;
  this.histories = {};
  this.stats = { messages: 0, nodes: 0, start: new Date() };
  this.connected = false;
  var wc = this;
  this.socket = new WebSocket("ws://" + location.hostname + ":8002");
  this.socket.onopen = ()=> {
    console.log("open");
    let e = $('#run_stop')
    e.click(()=>{
        if(e.text() == 'Run') {
            let msg = {type:'start',body:{
                id_start: parseInt($('#firstuserid').val()) || 1,
                id_count: parseInt($('#usercount').val()) || 1,
                per_sec: parseInt($('#stepusercount').val()) || 1,
                script: $('#scripts').val(),
            }}
            this.socket.send(JSON.stringify(msg))
            e.text('Stop')
        } else {
            this.socket.send(JSON.stringify({type:'stop'}))
            e.text('Run')
        }
    })
    //ws.send(JSON.stringify({type:'scripts'}));
  };
  this.socket.onmessage = function (ev) {
    let data = JSON.parse(ev.data);
    switch (data.type) {
      case "scripts":
        let e = $("#scripts");
        e.empty();
        data.body.forEach((f) => {
          if (f == "init.lua") return;
          e.append(
            `<option value='${f.substr(0, f.length - 4)}'>${f}</option>`
          );
        });
        return;
        case "log":
            return console.log(data.body)
        case "error":
            return console.error(data.body)
    }
  };
  this.socket.onclose = function (ev) {
    console.log("close");
  };
  this.socket.onerror = function (ev) {
    console.log("error");
  };
/*
  this.socket.on("connect", function () {
    wc.connected = true;
    wc.socket.emit("announce_web_client");
    var REPORT_INTERVAL = 3 * 1000;
    setInterval(function () {
      wc.socket.emit("webreport", {});
    }, REPORT_INTERVAL);

    var detailId = setInterval(function () {
      if (!!wc.detailTimer) {
        wc.socket.emit("detailreport", {});
      }
    }, REPORT_INTERVAL);
  });

  var isInited = false;
  //report status
  this.socket.on("webreport", function (snum, suser, stimeData, sincrData) {
    //doReport(timeData);
    $("#firstuserid").val(snum);
    $("#usercount").val(suser);
    updateIncrData(sincrData);
    updateTimesData(snum, suser, stimeData);
  });

  this.socket.on("detailreport", function (message) {
    doReportDetail(message);
  });

  this.socket.on("error", function (message) {
    $("#errorinput")
      .html("[" + message.node + "]:" + message.error)
      .end();
  });

  this.socket.on("statusreport", function (message) {
    var nodeId = message.id;
    var status = message.status;
    var hit = "";
    if (status === 0) {
      hit = "IDLE";
    }
    if (status == 1) {
      hit = "READY";
      $("#run-button").css("display", "");
    }
    if (status == 2) {
      hit = "RUNNING";
      $("#run-button").css("display", "none");
    }
    $("#hitdiv").html(hit);
  });

  // Update total message count stats
  this.socket.on("stats", function (message) {
    if (!wc.stats.message_offset) {
      wc.stats.message_offset = message.message_count;
    }
    wc.stats.messages = message.message_count - wc.stats.message_offset;
  });
  */
};

function doReportDetail(msg) {
  updateDetailAgent(msg.detailAgentSummary, " Summary");
  updateAvgAgent(msg.detailAgentAvg, " Response Time");
  updateEveryAgent(msg.detailAgentQs, "qs_div", " Qps Time");
}

try {
  exports.WebClient = WebClient;
} catch (err) {}
