$( document ).ready(function() {
    console.log( "ready!" );
    $('.ui.accordion').accordion();
    $('.ui.accordion').accordion({exclusive: false});
    $('.tabular.menu .item').tab();
    $('.ui.dropdown').dropdown({
      onShow: function(){
        console.log("showing modal");
        //$("#upIcon").remove();
      },
      action: 'nothing',
      direction: 'upward'
    }); //there is a direction: upward setting
    $('.ui.basic.modal').modal('show');
});

/* --------------------------------------------------------------------
This connects to the database given the inputs from
the form. The variables though are sent with an ajax request.
The line xhttp.send() sends the information to the server as a parameter.
I don't know the security implications of this and find a more accurate
way to send some input from a form securely with ajax and ExpressJS.
----------------------------------------------------------------------*/
function connectDB(){
  var username = document.getElementsByName('username')[0].value;
  var password = document.getElementsByName('password')[0].value;
  var dbname = document.getElementsByName('dbname')[0].value;

  console.log("we have: " + username + " + " + password + " + " + dbname);
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      //alert(this.responseText); //this is where we change the connection status. do some jquery
      if(this.responseText == "yes"){
        $('.ui.basic.modal').modal('hide');
      }
      //else do some nag or visual cue to enter stuff again
    }
  }
  xhttp.open("post", "/dbconnect", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('username='+username+'&password='+password+'&dbname='+dbname);

}

/* This function will load the initial graph on the browser. */
var nodes, edges, network;
var rootNodeSet, rootEdgeSet, rootNode, currentNodeID; //this last one will have to become an array currnodes

var options = {
  layout: {
    improvedLayout: true,
    hierarchical: {
      enabled: true,
      parentCentralization: false,
      blockShifting: true,
      edgeMinimization: true,
      sortMethod: 'directed',
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
  }
};

function nextStep(){
  loadNextNodes();
  loadNextEdges();
  currentNodeID++; //figure out how to change this correctly
}
//the next thing to do now is to turn the currentNodeID into an array of nodes, so we can do the
//function allStep() which expands many nodes at once.
//another thing to keep in mind is to expandSelectedNode() by using some vis.js functions
function loadNextNodes(){
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      console.log("loadnextnodes server response: " + this.responseText);
      console.log("loadnextnodes this.responseText typeof: " + typeof(JSON.parse(this.responseText)));
      rootNodeSet.add(JSON.parse(this.responseText));
    }
  }
  xhttp.open("post", "/loadNextNodes", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  console.log("currenteNodeID "+ currentNodeID);
  xhttp.send('currentNodeID='+currentNodeID);
}
//also keep in mind node duplicates and cycle edges and stuff
function loadNextEdges(){
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      console.log("loadnextedges server response: " + this.responseText);
      rootEdgeSet.add(JSON.parse(this.responseText));
    }
  }
  xhttp.open("post", "/loadNextEdges", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('currentNodeID='+currentNodeID);
}

function loadRoot(){
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      rootNode = JSON.parse(this.responseText);
      var container = document.getElementById('mynetwork');
      rootNodeSet = new vis.DataSet([{id: rootNode.curr, label: rootNode.curr}]);
      rootEdgeSet = new vis.DataSet();
      var data = {
        nodes: rootNodeSet,
        edges: rootEdgeSet
      };
      network = new vis.Network(container, data, options);
      network.on('click', function(params){
         $('#clickedNode').text("Selected node: " + params.nodes);
      });
      currentNodeID = rootNode.curr;
    }
  }
  xhttp.open("GET", "/loadRoot", true);
  xhttp.send();
  getTotalStates();
}

function loadGraph(){
  console.time('rendering network');
  loadNodes();
  loadEdges();

  //we might need threads here to solve the concurrency issue. i might have to block
  // whatever is in setTimeout until edges thread is loaded.
  setTimeout(function(){

    nodesDataSet = new vis.DataSet(JSON.parse(nodes));
    edgesDataSet = new vis.DataSet(JSON.parse(edges));
    var container = document.getElementById('mynetwork');
    var data = {
      nodes: nodesDataSet,
      edges: edgesDataSet
    };

    network = new vis.Network(container, data, options);
    console.timeEnd('rendering network');

  }, 50); // + - ? timeout

}//function loadGraph

/*This function will load the edge information from the database.
The information is saved on the edges variable. The format of the
information is an array of objects that hold necessary edge information.*/
function loadEdges(){
  console.time('loadEdges');
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      edges = this.responseText;
      console.timeEnd('loadEdges');
    }
  }
  xhttp.open("GET", "/loadEdges", true);
  xhttp.send();
}

/*The same principle applies here too*/
function loadNodes(){
  console.time('loadNodes');
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      nodes = this.responseText;
      console.timeEnd('loadNodes');
    }
  }
  xhttp.open("GET", "/loadNodes", true);
  xhttp.send();
}
/* In this part we get the network div and add an event listener to it
in order to interact with nodes */
// var graphDiv = document.getElementById('mynetwork');
// graphDiv.addEventListener('click', function(event){
//   network.on("click", function (params) {
//     params.event = "[original event]";
//     var nr = params.nodes[0];
//     var x = JSON.parse(nodes);
//     console.log(x[nr-1].label);
//     document.getElementById('nodeName').innerHTML = (""+x[nr-1].label);
//   });
// })

function findNodes(){
  var query = document.getElementById("queryBox").value;
  console.log(query);
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      var ids = JSON.parse(this.responseText);
      network.selectNodes(ids, true);
    }
  }
  xhttp.open("post", "/queryNodes", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('query='+query);
}

function getTotalStates(){
  var query = 'select * from "current_state";';
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      console.log("this is the response text from total states: " + this.responseText);
      var states = JSON.parse(this.responseText);
      $('#totalStates').text("Total number of states: "+ states);
    }
  }
  xhttp.open("post", "/queryTotalStates", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('query='+query);
}
