$( document ).ready(function() {
  console.log("DOM loaded.");

  $('.tabular.menu .item').tab();
  console.log("Tabs activated.");

  $('.ui.basic.modal').modal('show');
  console.log("Modal activated.");

  $('.ui.accordion').accordion({exclusive: false});
  console.log("Accordion activated.")

  $('#psql').click(function(){
    $('#psql').css("border-color", "#BF9B30");

    $('#psql').children('img').css("-webkit-filter","opacity(.4) drop-shadow(0 0 0 #BF9B30)");
    $('#psql').children('img').css("filter"," opacity(0.4) drop-shadow(0 0 0 #BF9B30)");

    $('#mysql').children('img').css("-webkit-filter","none");
    $('#mysql').children('img').css("filter"," none");

    $('#mysql').css("border-color", "transparent");
    selectedDatabase = "psql";
  });

  $('#mysql').click(function(){
    $('#mysql').css("border-color", "#BF9B30");

    $('#mysql').children('img').css("-webkit-filter","opacity(.4) drop-shadow(0 0 0 #BF9B30)");
    $('#mysql').children('img').css("filter"," opacity(0.4) drop-shadow(0 0 0 #BF9B30)");

    $('#psql').children('img').css("-webkit-filter","none");
    $('#psql').children('img').css("filter"," none");

    $('#psql').css("border-color", "transparent");
    selectedDatabase = "mysql";
  });

  $('#queryButton').popup();
  
  $('#queryButton').popup({
    on    : 'click'
  });


});


/* --------------------------------------------------------------------
This connects to the database given the inputs from
the form. The variables though are sent with an ajax request.
The line xhttp.send() sends the information to the server as a parameter.
I don't know the security implications of this and find a more accurate
way to send some input from a form securely with ajax and ExpressJS.
----------------------------------------------------------------------*/
var selectedDatabase;
function connectDB(){
  var username = document.getElementsByName('username')[0].value;
  var password = document.getElementsByName('password')[0].value;
  var dbname = document.getElementsByName('dbname')[0].value;
  console.log("Selected database on form send: " + selectedDatabase);
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      //alert(this.responseText); //this is where we change the connection status. do some jquery
      if(this.responseText == "yes"){
        $('.ui.basic.modal').modal('hide');
        console.log("Connected to " + dbname + " as " + username + ".");
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

function frontier(){
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
      console.log("Server passed these nodes: " + this.responseText);
      rootNodeSet.add(JSON.parse(this.responseText));
    }
  }
  xhttp.open("post", "/loadNextNodes", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  console.log("Node ID trying to expand: "+ currentNodeID);
  xhttp.send('currentNodeID='+currentNodeID);
}
//also keep in mind node duplicates and cycle edges and stuff
function loadNextEdges(){
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      console.log("Server passed these edges: " + this.responseText);
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
        $('#menu').hide();

        $('#clickedNode').text("Selected node "+ params.nodes);
      });
      network.on("oncontext", function (params) {
        console.log("clicked");
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

	       theNode = network.getNodeAt(params.pointer.DOM);
         console.log("theNode: " + theNode);
         //use this ^ to get node information
         $('#firstMenuItem').text("Node: "+theNode);
         $('#clickedNode').text("Selected node: "+theNode);
         menu.show();
         if(!(network.getNodeAt(params.pointer.DOM))){
           console.log("No node selected...");
           //change this to reflect in the context menu
           $('#firstMenuItem').text("Node: x");
           //refactor all thsi network.getnode
         }

        params.event = "[original event]"; //?
        network.selectNodes([theNode]);
      });
      currentNodeID = rootNode.curr;
    }
  }
  xhttp.open("GET", "/loadRoot", true);
  xhttp.send();
  getTotalStates();
}

function loadGraph(){
  console.time('Rendering network...');
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
    console.timeEnd('Rendering network...');

  }, 50); // + - ? timeout

}//function loadGraph

/*This function will load the edge information from the database.
The information is saved on the edges variable. The format of the
information is an array of objects that hold necessary edge information.*/
function loadEdges(){
  console.time('Loading edges from server...');
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      edges = this.responseText;
      console.timeEnd('Loading edges from server...');
    }
  }
  xhttp.open("GET", "/loadEdges", true);
  xhttp.send();
}

/*The same principle applies here too*/
function loadNodes(){
  console.time('Loading nodes from server...');
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      nodes = this.responseText;
      console.timeEnd('Loading nodes from server...');
    }
  }
  xhttp.open("GET", "/loadNodes", true);
  xhttp.send();
}

function getTotalStates(){
  var query = 'select * from "current_state";';
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      console.log("Total states number: " + this.responseText);
      var states = JSON.parse(this.responseText);
      $('#totalStates').text("Total states " + states);
    }
  }
  xhttp.open("post", "/queryTotalStates", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('query='+query);
}

function findNodes(){
  var query = document.getElementById("queryBox").value;
  console.log(query);
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      console.log("the data we got back is: " + this.responseText);
      var ids = JSON.parse(this.responseText);
      GenerateTable(ids);
      // if(this.responseText[0].next){
      //   console.log('it exists');
      // }else{
      //   console.log('it doesnt exit');
      // }
      //network.selectNodes(ids, true);  //find a way to select nodes if response has a 'next' attribute
      $('#clickedNode').text(""+ids);

      $('.ui.dropdown').dropdown('show');
    }
  }
  xhttp.open("post", "/queryNodes", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('query='+query);
}

function GenerateTable(data) {

  console.log(data);

  $('#queryTable tr').remove(); //reset
  var table = document.getElementById("queryTable");
  table.border = "1";

  //Get the count of columns.
  var columnCount = data[0].length;

  //Add the header row.
  var row = table.insertRow(-1);
  for (var i = 0; i < columnCount; i++) {
    var headerCell = document.createElement("TH");
    headerCell.innerHTML = data[0][i];
    row.appendChild(headerCell);
  }

  //Add the data rows.
  for (var i = 1; i < data.length; i++) {
    row = table.insertRow(-1);
    for (var j = 0; j < columnCount; j++) {
      var cell = row.insertCell(-1);
      cell.innerHTML = data[i][j];
    }
  }

}
