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
  var username = 'postgres'; //request.body.username;
  var password = 'password'; //request.body.password;
  var dbname = 'travel'; //request.body.dbname;
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
app.listen(port,function(){
  console.log('Listening on port ' + port)
})

app.post("/queryNodes", function(req, res){
  console.log("The query made it on the backend: "+ req.body.query);
  var query = client.query(req.body.query);
  var idArray = [];
  query.on('row', function(row, result){
    idArray.push(row.tso);
  });

  query.on('end', function(result){
    res.send(idArray);
  });
});

app.post("/loadNextNodes", function(req,res){
  var query = client.query('select distinct tso from edges where frosm = '+req.body.currentNodeID);
  var responseArray = [];
  query.on('row', function(row, result){
    responseArray.push({id: row.tso, label: row.tso});
  });
  query.on('end', function(result){
    res.send(responseArray);
  });
});

app.post("/loadNextEdges", function(req,res){
  var query = client.query("select * from edges where frosm ="+req.body.currentNodeID);
  var responseArray = [];
  query.on('row', function(row, result){
    curr = {from: row.frosm, to: row.tso, arrows: 'to'};
    responseArray.push(curr);
  });
  query.on('end', function(result){
    res.send(responseArray);
  });
});

app.get("/loadRoot", function(req,res){
  var query = client.query('select * from connection where id = 1');
  var rootNode;
  query.on('row', function(row, result){
    rootNode = {id: row.id, label: row.name};
  });
  query.on('end', function(result){
    res.send(rootNode);
  });
});


//This will load nodes from the connection table
//and put them into the resopnse array as an object
app.get("/loadNodes", function(request, response){

  var query = client.query('select * from connection');
  var responseArray = [];
  query.on('row', function(row, result) {
    curr = {id: row.id, label: row.name};
    responseArray.push(curr);
  });
  //here fix change to query on 'end'
  query.on('end', function(result){
    console.time('server loadNodes');
    response.send(responseArray);
    console.timeEnd('server loadNodes');
  });
});

app.get("/loadEdges", function(request, response){

  var query = client.query('select * from edges');
  var responseArray = [];
  query.on('row', function(row, result){
    curr = {from: row.frosm, to: row.tso, arrows: 'to'};
    responseArray.push(curr);
  });
  query.on('end', function(result){
    console.time('server loadEdges');
    response.send(responseArray);
    console.timeEnd('server loadEdges');
  });
});
