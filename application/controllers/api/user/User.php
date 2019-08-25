<?php

defined('BASEPATH') OR exit('No direct script access allowed');

class User extends MY_Controller {
    function __construct()
    {
        // Construct the parent class
        parent::__construct();
        $this->auth();
        $this->load->model('User_model');
    }
    public function adduser_post(){
//        echo "comming";
//        print_r($_POST);
        if(count($_POST)){
            $username=$this->post('username');
            $password=$this->post('password');
            if(!empty($username) && !empty($password)){
               $insert=$this->User_model->user_data($username,$password);
                if($insert){
                    $responce_arrray=['status'=>1,'Message'=>'Success'];

                    $this->response($responce_arrray,REST_Controller::HTTP_OK);
                }
                else{
                    $responce_arrray=['status'=>0,'Message'=>'Fail'];

                    $this->response($responce_arrray);

                } 
            }
            else{
            $responce_arrray=['status'=>0,'Message'=>'Fail','Resoponce'=>'Please Provide valid data'];
          
                $this->response($responce_arrray);
        }
            
        }
        
       
    }
    public function login_user_data_get(){
        print_r($this->user_data->id);
    }
}