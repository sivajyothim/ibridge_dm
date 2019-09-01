<?php

defined('BASEPATH') OR exit('No direct script access allowed');

class User extends MY_Controller {

    function __construct() {
        // Construct the parent class
        parent::__construct();
        $this->auth();
    }

    public function userData_get() {
        $userId = $this->user_data->id;
        if ($userId != "") {
            $query = $this->db->query("call usp_GetUserRoleClientDetails('" . $userId . "',@errorCode)");
            $result = $query->result_array();

            if ($result > 0) {
                $output = [
                    'status' => '1',
                    'Message' => 'Data Retrived Succesfully',
                    'Row count' => count($result),
                    'Responce' => $result,
                ];
                $this->set_response($output, REST_Controller::HTTP_OK); //This is the respon if success
            } else {
                $output = [
                    'status' => '0',
                    'Message' => 'No data found',
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
            }
        }else{
            $output = [
                    'status' => '0',
                    'Message' => 'Invalid Data Provided',
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
    }
    public function userClients_get() {
        $userId = $this->user_data->id;
        if ($userId != "") {
            $query = $this->db->query("call usp_GetUserClients('" . $userId . "',@errorCode)");
            $result = $query->result_array();

            if ($result > 0) {
                $output = [
                    'status' => '1',
                    'Message' => 'Data Retrived Succesfully',
                    'Row count' => count($result),
                    'Responce' => $result,
                ];
                $this->set_response($output, REST_Controller::HTTP_OK); //This is the respon if success
            } else {
                $output = [
                    'status' => '0',
                    'Message' => 'No data found',
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
            }
        }else{
            $output = [
                    'status' => '0',
                    'Message' => 'Invalid Data Provided',
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
    }
public function getClients_get() {
        $userId = $this->user_data->id;
        $userdata=$this->Main_model->userdata();
        $RoleId=$userdata->RoleId;
        if($RoleId==1){
            $clientId= "-1";
        }
        else{
            $clientId=0;
        }

        if ($userId != "") {
            $query = $this->db->query("call usp_GetClients('".$clientId."','" . $userId . "',@errorCode)");
            $result = $query->result_array();

            if ($result > 0) {
                $output = [
                    'status' => '1',
                    'Message' => 'Data Retrived Succesfully',
                    'Row count' => count($result),
                    'Responce' => $result,
                ];
                $this->set_response($output, REST_Controller::HTTP_OK); //This is the respon if success
            } else {
                $output = [
                    'status' => '0',
                    'Message' => 'No data found',
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
            }
        }else{
            $output = [
                    'status' => '0',
                    'Message' => 'Invalid Data Provided',
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
    }
    public function getUsers_get() {
        $userId = $this->user_data->id;
        $userdata=$this->Main_model->userdata();
        $RoleId=$userdata->RoleId;
        if($RoleId==1){
            $clientId= "-1";
        }
        else{
            $clientId=0;
        }

        if ($userId != "") {
            $query = $this->db->query("call usp_GetUsers('".$clientId."','" . $userId . "',@errorCode)");
            $result = $query->result_array();

            if ($result > 0) {
                $output = [
                    'status' => '1',
                    'Message' => 'Data Retrived Succesfully',
                    'Row count' => count($result),
                    'Responce' => $result,
                ];
                $this->set_response($output, REST_Controller::HTTP_OK); //This is the respon if success
            } else {
                $output = [
                    'status' => '0',
                    'Message' => 'No data found',
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
            }
        }else{
            $output = [
                    'status' => '0',
                    'Message' => 'Invalid Data Provided',
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
    }
}
