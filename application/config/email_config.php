<?php
$config['email_config_old'] = array(
	'protocol' 		=> 'smtp',
	'smtp_host' 	=> 'email-smtp.us-west-2.amazonaws.com',
	'smtp_port' 	=> 587,
	'smtp_user' 	=> 'AKIAIHFY4RLY3PV7TBEA', // change it to yours
	'smtp_pass' 	=> 'BHbay+Atzb8QoYDUtO13dczv+E6J6cYlzrNLt9P7Qyms', // change it to yours
	'smtp_crypto' 	=> "tls",
	/*'charset' 	=> 'iso-8859-1',
	'wordwrap' 		=> TRUE*/
	'charset'		=>'utf-8',
	'wordwrap'		=> TRUE,
	'mailtype' 		=> 'html',
	// 'newline' 		=> "\r\n"
);	
$config['email_config'] = array(
	'protocol' 		=> 'smtp',
	'smtp_host' 	=> 'smtp.danahermail.com',
	'smtp_port' 	=> 25,
	'smtp_user' 	=> '', // change it to yours
	'smtp_pass' 	=> '', // change it to yours
	/*'smtp_crypto' 	=> "",*/
	/*'charset' 	=> 'iso-8859-1',
	'wordwrap' 		=> TRUE*/
	'charset'		=>'utf-8',
	'wordwrap'		=> TRUE,
	'mailtype' 		=> 'html',
	
	// 'newline' 		=> "\r\n"
);




?>