$( document ).ready(function() {
    console.log( "ready!" );
    $('.ui.accordion').accordion();
    $('.ui.accordion').accordion({exclusive: false});
    var nodes = new vis.DataSet([
        {id: 1, label: 'Node 1'},
        {id: 2, label: 'Node 2'},
        {id: 3, label: 'Node 3'},
        {id: 4, label: 'Node 4'},
        {id: 5, label: 'Node 5'}
      ]);

      // create an array with edges
      var edges = new vis.DataSet([
        {from: 1, to: 3},
        {from: 1, to: 2},
        {from: 2, to: 4},
        {from: 2, to: 5},
        {from: 3, to: 3}
      ]);

      // create a network
      var container = document.getElementById('mynetwork');
      var data = {
        nodes: nodes,
        edges: edges
      };
      var options = {};
      var network = new vis.Network(container, data, options);

});


function myFunction(){
  var username = document.getElementsByName('username')[0].value;
  var password = document.getElementsByName('password')[0].value;
  var dbname = document.getElementsByName('dbname')[0].value;

  console.log("we have: " + username + " + " + password + " + " + dbname);
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      alert(this.responseText);
    }
  }
  xhttp.open("post", "/dbconnect", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  var object = {username: username};
  xhttp.send('username='+username+'&password='+password+'&dbname='+dbname);
}
