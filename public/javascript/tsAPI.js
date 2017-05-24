function getTotalStates(){
  var query = 'select * from "current_state";';
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      var states = JSON.parse(this.responseText);
      $('#totalStates').text("Total states: " + states);
    }
  }
  xhttp.open("post", "/queryTotalStates", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('query='+query);
}

function queryDatabase(){
  var query = document.getElementById("queryBox").value;
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      var ids = JSON.parse(this.responseText);
      GenerateTable(ids);
    }
  }
  xhttp.open("post", "/queryDatabase", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('query='+query);
}

function findNodes(){
  var query = document.getElementById("queryBox").value;
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      var ids = JSON.parse(this.responseText);

      console.log("after generate table: " + this.responseText);

      network.selectNodes(ids, true);  //find a way to select nodes if response has a 'next' attribute
      $('#clickedNode').text(""+ids);
    }
  }
  xhttp.open("post", "/findNodes", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('query='+query);
}

function GenerateTable(data) {

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
