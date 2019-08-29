<?php

defined('BASEPATH') OR exit('No direct script access allowed');
use \Firebase\JWT\JWT;

class Auth extends MY_Controller {

    function __construct()
    {
        // Construct the parent class
        parent::__construct();
        // Configure limits on our controller methods
        // Ensure you have created the 'limits' table and enabled 'limits' within application/config/rest.php
        $this->methods['users_get']['limit'] = 500; // 500 requests per hour per user/key
        $this->methods['users_post']['limit'] = 100; // 100 requests per hour per user/key
        $this->methods['users_delete']['limit'] = 50; // 50 requests per hour per user/key
    }

    

    public function login_post()
    {
        $this->post = file_get_contents('php://input');
        
        $u = $this->post('username'); //Username Posted
        $p = $this->post('password'); //Pasword Posted
        
        $kunci = $this->config->item('thekey');
        $invalidLogin = ['status' => '0','Message'=>'Inavalid Login']; //Respon if login invalid

        $query = $this->db->query("CALL usp_AuthenticateUser('".$u."','".$p."')");
        
        $val = $query->row(); //Model to get single data row from database base on username
       
        if($val->ErrorCode == -1){$this->response($invalidLogin, REST_Controller::HTTP_NOT_FOUND);}
        	$token['id'] = $val->UserId;  //From here
            $token['username'] = $u;
            $date = new DateTime();
            $token['iat'] = $date->getTimestamp();
            $token['exp'] = $date->getTimestamp() + 60*60*5; //To here is to generate token
           
            $token = JWT::encode($token,$kunci ); //This is the output token
            $output=['status' => '1','Message'=>'Login Success',"token"=>$token];
            $this->set_response($output, REST_Controller::HTTP_OK); //This is the respon if success
       
    }
    

}
