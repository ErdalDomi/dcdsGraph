$( document ).ready(function() {
  console.log("DOM loaded.");

  $('.tabular.menu .item').tab();
  console.log("Tabs activated.");

  $('.ui.basic.modal').modal('show');
  console.log("Modal activated.");

  $('.ui.accordion').accordion({exclusive: false});
  console.log("Accordion activated.");


  $('.message .close')
    .on('click', function() {
      $(this)
        .closest('.message')
        .transition('fade')
      ;
    })
  ;

  $('#psql').click(function(){
    $('#psql').css("border-color", "#BF9B30");

    $('#psql').children('img').css("-webkit-filter","opacity(.4) drop-shadow(0 0 0 #BF9B30)");
    $('#psql').children('img').css("filter"," opacity(0.4) drop-shadow(0 0 0 #BF9B30)");

    $('#mysql').children('img').css("-webkit-filter","none");
    $('#mysql').children('img').css("filter"," none");

    $('#mysql').css("border-color", "transparent");
  });

  $('#mysql').click(function(){
    $('#mysql').css("border-color", "#BF9B30");

    $('#mysql').children('img').css("-webkit-filter","opacity(.4) drop-shadow(0 0 0 #BF9B30)");
    $('#mysql').children('img').css("filter"," opacity(0.4) drop-shadow(0 0 0 #BF9B30)");

    $('#psql').children('img').css("-webkit-filter","none");
    $('#psql').children('img').css("filter"," none");

    $('#psql').css("border-color", "transparent");
  });

  $('#queryButton').popup();

  $('#queryButton').popup({
    on    : 'click'
  });


});
