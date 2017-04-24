var express = require('express')
var app = express()
var path = require('path')
var Client = require('pg').Client;
var connection = require('pg').Connection;
var bodyParser = require('body-parser')

app.use( bodyParser.json() );       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
  extended: true
}));

var client;

app.use(express.static(path.join(__dirname, 'public')))

app.post('/test', function(req, res){
  console.log(req.body.username + " " +req.body.password);
})
app.post("/dbconnect", function(request, response){
  console.log("got a dbconnect psot request");
  var username = request.body.username;
  var password = request.body.password;
  var dbname = request.body.dbname;
  //console.log("username: " + username + " \npassword: " + password + "\ndbname: " + dbname);
  client = new Client({
      user: username, //'postgres', //replace with username
      password: password, //'password', //password
      database: dbname,//'travel', //dbname
      host: '127.0.0.1',
      port: 5432
    });
  connection = client.connect(function(err){
    if(err){
      console.log("error connecting ", err);
    }
  });
  console.log('Database connection established');
  response.send('hey.');
});
app.listen(8000,function(){
  console.log('Listening on port 8000')
})
