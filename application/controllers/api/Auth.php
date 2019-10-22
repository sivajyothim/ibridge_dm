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
        header('Access-Control-Allow-Origin: *'); 
    }

    

    public function login_post()
    {
        $this->post = file_get_contents('php://input');
        
        $u = $this->post('username'); //Username Posted
        $p = $this->post('password'); //Pasword Posted
        $userTimeZone = $this->post('offset'); //ist/utc/est/
        
        $kunci = $this->config->item('thekey');
        
        $canShowGenericErrorMessageToUser=false;
        try 
        {
            $query = $this->db->query("CALL usp_AuthenticateUser('".$u."','".$p."',@errorCode,@errorMessage)");
//            $this->db->last_query();
            $result = $query->result();
//            print_r($result);exit;
            if(isset($result[0]->ErrorCode))
            {
                if($result[0]->ErrorCode == 45000)
                {
                    // error in DB - CUSTOM MESSAGE
                    throw new Exception(substr($result[0]->ErrorMessage, strpos($result[0]->ErrorMessage, ":") + 1)); 
                }
                else
                {
                    // error in DB - Generic Message
                   // log_message('error', 'Database:'.$result[0]->ErrorMessage);
                    $canShowGenericErrorMessageToUser = true;
                    throw new Exception($result[0]->ErrorMessage); 
                }
                
            }
            else
            {
                // success in DB
       
            $token['id'] = $result[0]->UserId;  //From here
            $token['username'] = $u;
            $date = new DateTime();
            $token['iat'] = $date->getTimestamp();
            $token['exp'] = $date->getTimestamp() + 60*60*5; //To here is to generate token
            $token['RoleId']=$result[0]->RoleId;
            $token['ClientId']=$result[0]->ClientId;
            $token['userTimeZone']=$userTimeZone;
            
            $token = JWT::encode($token,$kunci ); //This is the output token
            $output=[
                'status' => '1',
                'Message'=>'Login Success',
                "token"=>$token,
                'User Id' => $result[0]->UserId,
                'Is Default Password Changed'=>$result[0]->IsDefaultPasswordChanged,
                    ];
            $this->set_response($output, REST_Controller::HTTP_OK); //This is the respon if success
       
            }
        }
        catch (Exception $e)
        {
            log_message('error', 'Database:'.$e->getMessage());
            
            $output = [
                    'status' => '0',
                    'Message' => $canShowGenericErrorMessageToUser == true ? GENERIC_ERROR_MESSAGE : $e->getMessage(), //'Failed to save Data',substr($e->getMessage(), strpos($e->getMessage(), ":") + 1)
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
        
        
    }
    

}
