
id_comcntsrv_count = function() {
    jQuery.post(id_comcntsrv_url)
}

id_add_action('comment_post',id_comcntsrv_count);
