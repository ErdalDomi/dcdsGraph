$( document ).ready(function() {
    console.log( "ready!" );
    $('.ui.accordion').accordion();
    $('.ui.accordion').accordion({exclusive: false});
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
    }
  }
  xhttp.open("post", "/dbconnect", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('username='+username+'&password='+password+'&dbname='+dbname);
}

/* This function will load the initial graph on the browser. */
var nodes = [];
var edges = [];
var network;
var options = {
  nodes: {
    color: {
      border: '#A2C5AC',
      background: '#7F6A93'
    }
  }
};

function loadGraph(){
  console.time('loading network');
  loadNodes();
  loadEdges();
  console.timeEnd('loading network');

  setTimeout(function(){
    //We need to "treat" the nodes so we convert them to a format vis.js can understand
    var treatedNodes = [];
    JSON.parse(nodes).forEach(function(currentNode){
      var curr = {id: currentNode.id, label: currentNode.id};
      treatedNodes.push(curr);
    });
    console.log(treatedNodes);
    var treatedEdges = [];
    JSON.parse(edges).forEach(function(currentEdge){
      var curr = {from: currentEdge.from, to: currentEdge.to, arrows: currentEdge.arrows};
      treatedEdges.push(curr);
    });
    console.log(treatedEdges);
    var container = document.getElementById('mynetwork');
    var data = {
      nodes: treatedNodes,
      edges: treatedEdges
    };
    options = {
      nodes: {
        font: {
          color: '#e3b23c'
        },
        color: {
          border: '#F0B67F',
          background: '#FE5F55',
          highlight: {
            border: '#e3b23c',
            background: '#423E37'
          }
        }
      }
    };
    network = new vis.Network(container, data, options);
    network.setOptions(options);
  }, 100); // + - ?

}

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
var graphDiv = document.getElementById('mynetwork');
graphDiv.addEventListener('click', function(event){
  network.on("click", function (params) {
    params.event = "[original event]";
    var nr = params.nodes[0];
    var x = JSON.parse(nodes);
    console.log(x[nr-1].label);
    document.getElementById('nodeName').innerHTML = (""+x[nr-1].label);
  });
})
