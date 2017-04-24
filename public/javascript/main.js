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

function submitForm(){

  document.getElementById('databaseForm').submit();
  //the page refreshes so we cant edit html yet
  //thats why we need an ajax request to the server to make the db connection
  //after we get the ok response from server
  //then we signal to the user by adding a connection status
  //or disabling the form in some way
}
