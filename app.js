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
  var username = request.body.username;
  var password = request.body.password;
  var dbname = request.body.dbname;
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

//This will load nodes from the connection table
//and put them into the resopnse array as an object
app.get("/loadNodes", function(request, response){

  var query = client.query('select * from connection');
  var responseArray = [];
  query.on('row', function(row, result) {
    curr = {id: row.id, label: row.name};
    responseArray.push(curr);
  });
  setTimeout(function(){
    console.time('server loadNodes');
    response.send(responseArray);
    console.timeEnd('server loadNodes');
  }, 50 );
});

app.get("/loadEdges", function(request, response){

  var query = client.query('select * from edges');
  var responseArray = [];
  query.on('row', function(row, result){
    curr = {from: row.frosm, to: row.tso, arrows: 'to'};
    responseArray.push(curr);
  });
  setTimeout(function(){
    console.time('server loadEdges');
    response.send(responseArray);
    console.timeEnd('server loadEdges');
  }, 50);
});
