var express = require('express')
var app = express()
var path = require('path')
var Client = require('pg').Client;
var connection = require('pg').Connection;
var bodyParser = require('body-parser')

app.use( bodyParser.json() );       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({extended:true}));  // to support URL-encoded bodies



var client; //we use this to query the database

//this is to serve static files like html and css from
//the public folder
app.use(express.static(path.join(__dirname, 'public')))

/*This will get the information from the ajax request and
create a connection to the db. Then we use the variable
client to query the database.*/
app.post("/dbconnect", function(request, response){
  console.log("got a dbconnect psot request");
  var username = request.body.username;//'postgres'; //request.body.username;
  var password = request.body.password;//'password'; //request.body.password;
  var dbname = request.body.dbname;//'dcds'; //request.body.dbname;
  var connectionStatus = "yes"; //to keep track of the connection status
  client = new Client({
      user: username,
      password: password,
      database: dbname,
      host: '127.0.0.1',
      port: 5432
    });
  connection = client.connect(function(err){
    if(err){
      console.log("error connecting ", err);
      connectionStatus = "no"; //still an issue when we dont get a proper connection
    }
  });
  console.log('Connected to '+dbname + ' as user ' +username);
  response.send(connectionStatus);
});

//Start the app
var port = 8000;
var onServerStart = function() {
  console.log("Listening on port " + port);
}
app.listen(port,onServerStart);

app.post("/queryNodes", function(req, res){
  var columnNames = new Array();
  var query = client.query(req.body.query, function(err, result){
    var firstRow = result.rows[0];
    for(var columnName in firstRow) {
      columnNames.push(columnName);
    }
  });
  var responseArray = [];
  var currentRow = [];
  responseArray.push(columnNames);
  query.on('row', function(row, result){
    for(var elements in row){
      currentRow.push(row[elements]);
    }
    responseArray.push(currentRow);
    currentRow = [];
  });

  query.on('end', function(result){
    console.log('sending back ' + responseArray + ' to client');
    res.send(responseArray);
  });
});

app.post("/queryTotalStates", function(req, res){
  console.log("The total states query made it on the backend: "+ req.body.query);
  var query = client.query(req.body.query);
  var idArray = [];
  query.on('row', function(row, result){
    idArray.push(row.state);
  });

  query.on('end', function(result){
    res.send(idArray);
  });
});

app.post("/loadNextNodes", function(req,res){

  var query = client.query('select next from "TS" where curr = '+req.body.currentNodeID);

  var responseArray = [];
  query.on('row', function(row, result){
    console.log("row next: " + row.next);
    responseArray.push({id: row.next, label: row.next});
  });
  query.on('end', function(result){
    res.send(responseArray);
  });
});

app.post("/loadNextEdges", function(req,res){

  var query = client.query('select * from "TS" where curr ='+req.body.currentNodeID);

  var responseArray = [];
  query.on('row', function(row, result){

    var currLabel = '('+row.action+','+row.binding+')';
    curr = {from: row.curr, to: row.next, arrows: 'to', label: currLabel };
    responseArray.push(curr);
  });
  query.on('end', function(result){
    res.send(responseArray);
  });
});

app.get("/loadRoot", function(req,res){
  var query = client.query('select * from "TS" where curr = 1');
  var rootNode;
  query.on('row', function(row, result){
    rootNode = {curr: row.curr, label: ""+row.action+" "+row.binding};
  });
  query.on('end', function(result){
    res.send(rootNode);
  });
});


//This will load nodes from the connection table
//and put them into the resopnse array as an object
app.get("/loadNodes", function(request, response){

  var query = client.query('select distinct curr from "TS"');
  var responseArray = [];
  query.on('row', function(row, result) {
    curr = {id: row.curr, label: row.curr};
    responseArray.push(curr);
  });
  query.on('end', function(result){
    console.time('server loadNodes');
    response.send(responseArray);
    console.log("load nodes response array: " + responseArray);
    console.timeEnd('server loadNodes');
  });
});

app.get("/loadEdges", function(request, response){

  var query = client.query('select * from "TS"');
  var responseArray = [];
  query.on('row', function(row, result){
    var currLabel = '('+row.action+','+row.binding+')';
    curr = {from: row.curr, to: row.next, arrows: 'to', label: currLabel };
    responseArray.push(curr);
  });
  query.on('end', function(result){
    console.time('server loadEdges');
    console.log("load edges response array: " + responseArray);
    response.send(responseArray);
    console.timeEnd('server loadEdges');
  });
});
