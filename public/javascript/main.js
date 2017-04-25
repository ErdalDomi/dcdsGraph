$( document ).ready(function() {
    console.log( "ready!" );
    $('.ui.accordion').accordion();
    $('.ui.accordion').accordion({exclusive: false});
    $('.tabular.menu .item').tab();
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
var nodes, edges, network, treatedNodes, treatedEdges;
var rootNodeSet, rootEdgeSet, rootNode, currentNodeID; //this last one will have to become an array currnodes

var options = {
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
  currentNodeID++;
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
      rootNodeSet = new vis.DataSet([{id: rootNode.id, label: rootNode.id}]);
      rootEdgeSet = new vis.DataSet();
      var data = {
        nodes: rootNodeSet,
        edges: rootEdgeSet
      };
      network = new vis.Network(container, data, options);
      currentNodeID = rootNode.id;
    }
  }
  xhttp.open("GET", "/loadRoot", true);
  xhttp.send();

}

function loadGraph(){
  console.time('loading network');
  loadNodes();
  loadEdges();
  console.timeEnd('loading network');
  //we might need threads here to solve the concurrency issue. i might have to block
  // whatever is in setTimeout until edges thread is loaded.
  setTimeout(function(){
    //We need to "treat" the nodes so we convert them to a format vis.js can understand
    treatedNodes = [];
    JSON.parse(nodes).forEach(function(currentNode){
      var curr = {id: currentNode.id, label: currentNode.id};
      treatedNodes.push(curr);
    });
    console.log(treatedNodes);
    treatedEdges = [];
    JSON.parse(edges).forEach(function(currentEdge){
      var curr = {from: currentEdge.from, to: currentEdge.to, arrows: currentEdge.arrows};
      treatedEdges.push(curr);
    });
    console.log(treatedEdges);

    nodesDataSet = new vis.DataSet(treatedNodes);
    edgesDataSet = new vis.DataSet(treatedEdges);
    var container = document.getElementById('mynetwork');
    var data = {
      nodes: nodesDataSet,
      edges: edgesDataSet
    };
    network = new vis.Network(container, data, options);

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
