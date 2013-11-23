var Pageantus = {
  get_path: function(desired_path){
    return $('#server_address').val() + desired_path;
  },
	genders: ['All', 'Female', 'Male']
};

$(document).ready(function(){
  //add fade in effect on load
  // $('body').fadeIn();


  $('#backup-database').on('click', function(){
    $.get(Pageantus.get_path('backup'), function(data){alert(data)});
  })

  $('.toggle-candidate-active').on('click', function(){
    var context = $(this);
    
    $.put(Pageantus.get_path('candidate'),
    {
      id: context.attr('candidate-id'),
      is_active: context.attr('candidate-active') == 'true' ? false : true
    },
    function(data){
      if (context.attr('candidate-active') == 'true'){
        context.removeClass('btn-primary');
        context.addClass('btn-danger');
        context.attr('candidate-active', 'false');
        context.text('Inactive')
      }else{
        context.addClass('btn-primary');
        context.removeClass('btn-danger');
        context.attr('candidate-active', 'true');
        context.text('Active')

      }

      
    }
      )

  })




  $('.generate-report').on('click', function(){
    var context = $(this);
    context.removeClass('active');
    window.open(context.attr('report-location') ,'_blank');
  })

  $('.activate-category').on('click', function(){
    var context = $(this)
    $.put(Pageantus.get_path('activate/category/' + context.attr('category-id')),
            function(data){
              $('tr.active').removeClass('active')
              context.closest('tr').addClass('active')
              $('#navbar-current-category').text(context.attr('category-name'))
            }
          )
  })



  $('.submit-category').on('click', function(){
    var context = $(this)
    $.put(Pageantus.get_path('submit'), {id: context.attr('category-id'), is_ready: !context.hasClass('active')}, function(data){
      
        
        context.closest('tr').hasClass('submitting') ? context.closest('tr').removeClass('submitting') : context.closest('tr').addClass('submitting')
      });
  })





	$('#dash a').click(function(e){
		e.preventDefault();
		$(this).tab('show');
	})

	$.getJSON(Pageantus.get_path('candidate'), function(data){
		for (i in data) {
			

			// Modify tab
			  $('#manual-input-candidate').append($('<option>', {
				    value: data[i].id,
				    text: data[i].first_name + " " + data[i].last_name 
				}))
			}

	})

	$.getJSON(Pageantus.get_path('judge'), function(data){
		for (i in data) {
			  // $('#judges-table > tbody:last').append('<tr><td>'+data[i].number+'</td><td>'+data[i].name+"</td><td>"+data[i].ip_address+'</td><td>'+data[i].assistant+'</td><td>'+'<span class="label label-danger">No</span>'+'</td></tr>');

			// Modify tab
			  $('#manual-input-judge').append($('<option>', {
				    value: data[i].id,
				    text: data[i].name
				}))
			  
			}
	})

  $.getJSON(Pageantus.get_path('active/category'), function(data){$('#navbar-current-category').text(data.long_name)});

  

	$.getJSON(Pageantus.get_path('category'), function(data){
		
		for (i in data) {
			// Modify tab
			$('#manual-input-category, #report-generate-category').append($('<option>', {
				    value: data[i].id,
				    text: data[i].long_name
				}))
			}

	})

	$('#manual-input-submit').on('click', function(){
		$.post(Pageantus.get_path('score'), {
				pageant_id: 1,
				judge_id: $('#manual-input-judge').val(),
				category_id: $('#manual-input-category').val(),
				candidate_id: $('#manual-input-candidate').val(),
				score: $('#manual-input-score').val()
			},
				function(data){
					alert(data)

				}
			)
	})

})