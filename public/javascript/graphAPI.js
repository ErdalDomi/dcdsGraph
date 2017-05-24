var nodes = "";
var edges = "";
var currentNodeIDs=[]; //the list of frontier nodes waiting to be expanded
var existingNodeIDs = []; //to check if node already exists before inserting
var fullGraphLoaded = false;
var network = "";
$( document ).ready(function() {
  startGraph();
  setNetworkMenu();
  setNetworkEdge();
});

function startGraph(){
  nodes = new vis.DataSet();
  edges = new vis.DataSet();
  var data = {
    nodes: nodes,
    edges: edges
  };
  var options = {
    layout: {
      improvedLayout: true,
      hierarchical: {
        enabled: false,
        parentCentralization: false,
        blockShifting: false,
        edgeMinimization: false,
        sortMethod: 'hubsize',
        direction: 'LR'
      }
    },
    nodes: {
      size: 35,
      color: {
        border: '#798071',
        background: '#353D2F',
        highlight: {
          border: '#6BA368',
          background: '#519872'
        },
        hover: {
          border: '#6BA368',
          background: '#D2E5FF'
        }
      },
      font: {
        color: '#D3D5D4',
        size: 14, //px
        strokeColor: '#fff',
        align: 'center'
      },
      shape: 'circle'
    },
    physics: {
      barnesHut: {
        gravitationalConstant: -5500,
        centralGravity: 0.75,
        springLength: 0,
        damping: 0.2,
        avoidOverlap: 1
      },
      minVelocity: 0.75
    }
  };
  var container = document.getElementById('mynetwork');
  network = new vis.Network(container, data, options);
}

function setNetworkEdge(){
  network.on('selectEdge', function(params){
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function(){
      if(this.readyState == 4 && this.status == 200){
        edgeLabel = JSON.parse(this.responseText);
        edges.update({id: params.edges[0], label: '('+edgeLabel.action+','+edgeLabel.binding+')'});
      }
    }
    xhttp.open("post", "/getEdgeLabel", true);
    xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhttp.send('from='+edges.get(params.edges[0]).from+'&to='+edges.get(params.edges[0]).to);
  });

  network.on('selectEdge',function(params){
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function(){
      if(this.readyState == 4 && this.status == 200){
        bindingInfo = JSON.parse(this.responseText);
        console.log("binding info back: " + bindingInfo);
        // edges.update({id: params.edges[0], label: '('+edgeLabel.action+','+edgeLabel.binding+')'});
        //jquery here
        var html = "";
        for(var field in bindingInfo){
          html = html + '<p>'+field+': '+bindingInfo[field]+'</p>'
        }
        //
        $('#bindingInformation').html(html);
      }
    }
    xhttp.open("post", "/getBindingInfo", true);
    xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhttp.send('from='+edges.get(params.edges[0]).from+'&to='+edges.get(params.edges[0]).to);
  });
}


function setNetworkMenu(){
  network.on('click', function(params){
    $('#menu').hide();
    $('#clickedNode').text("Selected node "+ params.nodes);
  });
  network.on("oncontext", function (params) {

    $("#mynetwork").contextmenu(function(){
      return false;
    });

    var menu = $('#menu');

     //hide menu if already shown
     menu.hide();
     console.log(params.pointer.DOM);
     //get x and y values of the click event
     var pageX = params.pointer.DOM.x;
     var pageY = params.pointer.DOM.y;


     //position menu div near mouse cliked area
     menu.css({top: pageY , left: pageX});
     var mwidth = menu.width();
     var mheight = menu.height();
     var screenWidth = $(window).width();
     var screenHeight = $(window).height();

     //if window is scrolled
     var scrTop = $(window).scrollTop();

     //if the menu is close to right edge of the window
     if(pageX+mwidth > screenWidth){
      menu.css({left:pageX-mwidth});
     }

     //if the menu is close to bottom edge of the window
     if(pageY+mheight > screenHeight+scrTop){
      menu.css({top:pageY-mheight});
     }

     try {
       theNode = network.getNodeAt(params.pointer.DOM);
       $('#firstMenuItem').text("Node: "+theNode);
       $('#clickedNode').text("Selected node: "+theNode);
       network.selectNodes([theNode]);
     } catch (e) {
       console.log("No node here.");
       $('#firstMenuItem').text("Node: --");
     } finally {

     }
     menu.show();
  });

}

function loadInitialState(){
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      rootNode = JSON.parse(this.responseText);
      if(existingNodeIDs.length > 0){ //reseting graph
        nodes.clear();
        edges.clear();
        currentNodeIDs = [];
        existingNodeIDs = [];
      }
      nodes.add({id:rootNode.curr, label:rootNode.curr});
      currentNodeIDs.push(rootNode.curr);
      existingNodeIDs.push(rootNode.curr);
    }
  }
  xhttp.open("GET", "/loadInitialState", true);
  xhttp.send();
  fullGraphLoaded = false;
}

function loadFrontier(){
  if(fullGraphLoaded == false){
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function(){
      if(this.readyState == 4 && this.status == 200){
        var rows = JSON.parse(this.responseText);
        for(var i=0, len = rows.length; i<len; i++){
          if(existingNodeIDs.indexOf(rows[i].next) == -1){
            nodes.add({id: rows[i].next, label: rows[i].next});
            currentNodeIDs.push(rows[i].next);
            existingNodeIDs.push(rows[i].next);
          }
          edges.add({from: rows[i].curr, to: rows[i].next, arrows: 'to'}); //, label: '('+rows[i].action+','+rows[i].binding+')'
        }
      }
    }
    xhttp.open("post", "/loadFrontier", true);
    xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhttp.send('currentNodeID='+currentNodeIDs.pop());
  }else{
    console.log("can't expand frontier with a full graph");
  }

}

function loadFullGraph(){
  console.time('fullGraph');
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      console.log(this.responseText);
      if(existingNodeIDs.length > 0){ //reseting graph
        nodes.clear();
        edges.clear();
        existingNodeIDs = [];
      }
      console.log('reset the graph successfully: ' + existingNodeIDs );
      var rows = JSON.parse(this.responseText);
      for(var i=0, len = rows.length; i<len; i++){
        if(existingNodeIDs.indexOf(rows[i].curr) == -1){
          nodes.add({id: rows[i].curr, label: rows[i].curr});
          existingNodeIDs.push(rows[i].curr);
          console.log(existingNodeIDs);
        }
        if(existingNodeIDs.indexOf(rows[i].next) == -1){
          nodes.add({id: rows[i].next, label: rows[i].next});
          existingNodeIDs.push(rows[i].next);
          console.log(existingNodeIDs);
        }
        edges.add({from: rows[i].curr, to: rows[i].next, arrows: 'to'}); //, label: '('+rows[i].action+','+rows[i].binding+')'
      }
      console.timeEnd('fullGraph');
    }
  }
  xhttp.open("GET", "/loadFullGraph", true);
  xhttp.send();
  fullGraphLoaded=true;
}
