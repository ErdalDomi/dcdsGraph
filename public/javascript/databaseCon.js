$( document ).ready(function() {
  $('#psql').click(function(){
    selectedDatabase = "psql";
  });
  $('#mysql').click(function(){
    selectedDatabase = "mysql";
  });
});

var selectedDatabase;
function connectDB(){
  var username = document.getElementsByName('username')[0].value;
  var password = document.getElementsByName('password')[0].value;
  var dbname = document.getElementsByName('dbname')[0].value;

  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function(){
    if(this.readyState == 4 && this.status == 200){
      if(this.responseText == "no"){
        $('#negativeMessage').addClass('visible');
        $('#negativeMessage').removeClass('hidden');
      }
      else if(this.responseText == "yes"){
        $('.ui.basic.modal').modal('hide');
        getTotalStates();
      }
    }
  }
  
  xhttp.open("post", "/dbconnect", true);
  xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhttp.send('username='+username+'&password='+password+'&dbname='+dbname+'&dbtype='+selectedDatabase);
}
