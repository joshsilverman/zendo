function vote(amnt, tag_id){
	var params = {"tag_id": tag_id, "rating":amnt};

        new Ajax.Request('/tags/rating_vote', {
            method: 'post',
            parameters: params,
            onFailure: function(){
                console.log("Error sending vote!");
            },
            onSuccess: function(res){
                        console.log("success!");
                        console.log(res);
                        console.log((res.responseJSON.width));
                        console.log(res.responseJSON.status);
			$('current-rating').setStyle({"width":res.responseJSON.width+"px"});
                        $('current-rating').setStyle({"background":"url(../../images/shared/alt_star.gif) left bottom"});
            }
        });
}