var express = require('express')
var app = express()
var path = require('path')
var bodyParser = require('body-parser');

var psql = require('pg');
var Client = require('pg').Client;
var psqlConnection = require('pg').Connection;

var mysql = require('mysql');
var mysqlConnection;

app.use( bodyParser.json() );       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({extended:true}));  // to support URL-encoded bodies

var client; //we use this to query the database
var sessionDBtype;
//this is to serve static files like html and css from
//the public folder
app.use(express.static(path.join(__dirname, 'public')))

//Start the app
var port = 8000;
var onServerStart = function() {
  console.log("Listening on: localhost:" + port);
}
app.listen(port,onServerStart);

/*This will get the information from the ajax request and
create a connection to the db. Then we use the variable
client to query the database.*/
app.post("/dbconnect", function(request, response){
  var username =  request.body.username;//'postgres';
  var password = request.body.password; //'password';
  var dbname =  request.body.dbname;//'dcds128';
  var dbtype = request.body.dbtype;
  sessionDBtype = request.body.dbtype;

  if(dbtype == "psql"){
    client = new Client({
        user: username,
        password: password,
        database: dbname,
        host: '127.0.0.1',
        port: 5432
      });

    psqlConnection = client.connect(function(err){
      if(err){
        console.log("There was a credential problem connecting to the database. Note that we're using host 127.0.0.1 and port 5432 to connect. \n ", err);
        response.send("no");
      }else{
        response.send("yes");
        console.log('Successfully connected to '+ dbname + ' as user ' + username);
      }
    });

  }else if(dbtype == "mysql"){
    mysqlConnection = mysql.createConnection({
      host  :   'localhost',
      user  :   'root',
      password  : 'password',
      database  : 'dcds'
    });
    mysqlConnection.connect(function(err){
      if(err){
        console.log("There was a credential problem connecting to the database. \n", err);
        response.send("no");
      }else{
        console.log("Successfully connected to mysql dcds database as root");
        response.send("yes");
      }
    });

  } //end else dbtype mysql


});

app.get("/loadInitialState", function(req,res){
  if(sessionDBtype == 'psql'){
    var query = client.query('select * from "TS" where curr = 1');
    query.on('error', function(error){
      console.log("Problem loading initial state");
    });
    query.on('end', function(result){
      res.send(result.rows[0]);
    });
  }else if (sessionDBtype == 'mysql'){
    //mysql code here
  }
});

app.post("/loadFrontier", function(req,res){
  if(sessionDBtype == 'psql'){
    var query = client.query('select * from "TS" where curr ='+req.body.currentNodeID);
    query.on('error', function(error){
      console.log("Can't expand anymore. " + error+". Node trying to expand: "+req.body.currentNodeID);
      res.send({id: 1, label:'1'}); //this because the graph wont allow a repeated node and root is always there
    });
    query.on('end', function(result){
      res.send(result.rows);
    });
  }else if (sessionDBtype == 'mysql'){
    //mysql code here
  }
});

app.get("/loadFullGraph", function(request, response){

  if(sessionDBtype == 'psql'){
    var query = client.query('select * from "TS"');
    query.on('error', function(error){
      console.log("problem loading full graph " + error);
    });
    query.on('end', function(result){
      response.send(result.rows);
    });
  }else if (sessionDBtype == 'mysql'){
    var query = mysqlConnection.query('select * from graphStub', function(error, results, fields){
      if(error) throw error;
      response.send(results);
    });
  }
});

app.post("/queryDatabase", function(req, res){
  var columnNames = new Array();
  var query = client.query(req.body.query, function(err, result){
    if(err){
      console.log("There was an error with the query. " + err);
    } else {
      var firstRow = result.rows[0];
      for(var columnName in firstRow) {
        columnNames.push(columnName);
      }
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
    res.send(responseArray);
  });


});

app.post("/queryTotalStates", function(req, res){
  var query = client.query(req.body.query);
  var idArray = [];
  query.on('row', function(row, result){
    idArray.push(row.state);
  });

  query.on('end', function(result){
    res.send(idArray);
  });
});

app.post("/getEdgeLabel", function(req,res){
  if(sessionDBtype == 'psql'){
    var query = client.query('select * from "TS" where curr = '+req.body.from+' and next = '+req.body.to+';');

    query.on('error', function(error){
      console.log("There was an error getting edge label. Restart app" + error);
    });

    query.on('end', function(result){
      res.send(result.rows[0]);
    });



  }else if (sessionDBtype == 'mysql'){
    //mysql code here
  }
});

app.post("/getBindingInfo", function(req,res){
  if(sessionDBtype == 'psql'){
    var query = client.query('select * from "TS" where curr = '+req.body.from+' and next = '+req.body.to+';');

    query.on('end', function(result){

      var action = result.rows[0].action;
      var binding = result.rows[0].binding;

      var query2 = client.query('select * from ' +action + '_params where param_id = '+ binding+';');

      query2.on('end', function(result){
        res.send(result.rows[0]);
      });

      query2.on('error', function(error){
        console.log("There was an error getting binding information. " + error);
      });
    });

    query.on('error', function(error){
      console.log("There was an error getting edge label. " + error);
    });



  }else if (sessionDBtype == 'mysql'){
    //mysql code here
  }
});

app.post("/findNodes", function(req,res){
  if(sessionDBtype == 'psql'){
    var query = client.query(req.body.query);
    var idArray = [];

    query.on('row', function(row,result){
      idArray.push(row.curr);
    });

    query.on('end', function(result){
      res.send(idArray);
    });

    query.on('error', function(error){
      console.log("there was an error with query nodes. " + error);
    });
  }else if (sessionDBtype == 'mysql'){
    //mysql code here
  }
});
