Cufon.replace('#head .row h2', { hover: true});
Cufon.replace('#content h3');

$(document).ready(function(){
	
	/* Field Focus */
	
	$('.blink').focus(function(){
		if( $(this).attr('title') == $(this).val() ) {
			$(this).val('');
		}
	}).blur(function(){
		if( $(this).val() == '' ) {
			$(this).val( $(this).attr('title') );
		}
	});
	
	
	/* End Field Focus */
	
	
	/* Drop Down */
	
	$('.login-link').click(function () {
		var added_div = $(this).parent().find('.dd');
		
		if( added_div.css('display') == 'none' ){
			added_div.show();
		}else {
			added_div.hide();
		}
		
		return false;
	});
	
	$('a.login-link-hr').live('click', function(){
		$('.dd').hide();
		return false;
	})
	
	/* End Drop Down */
	
	
});