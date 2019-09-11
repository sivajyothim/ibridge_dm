<?php

defined('BASEPATH') OR exit('No direct script access allowed');

class Services extends MY_Controller {

    function __construct() {
        // Construct the parent class
        parent::__construct();
        $this->auth();
    }

    public function clientServices_get() {
        
            $userdata=$this->Main_model->userdata();
            $query = $this->db->query("call usp_GetClientServices(".$this->user_data->id.",".$userdata->ClientId.",@errorCode)");
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
    }
    public function getServiceType_get() {

        $query = $this->db->query("call usp_GetServiceTypes(@errorCode)");
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
    }
    public function getServices_post() {
        $this->post = file_get_contents('php://input');
        $userId=$this->user_data->id;
        $serviceId=$this->post('serviceId');
        $query = $this->db->query("call usp_GetServices('" . $serviceId . "','".$userId."',@errorCode)");

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
    }
     public function manageServiceold_post() {
        $this->post = file_get_contents('php://input');
        $serviceId=$this->post('serviceId');
        $serviceTypeId=$this->post('serviceTypeId');
        $serviceName=$this->post('serviceName');
        $active=$this->post('active');
        $userId = $this->user_data->id;
        
        $query = $this->db->query("call usp_SetService(" . $serviceId . "," . $serviceTypeId . ",'" . $serviceName . "'," . $userId . "," . $active . ",@errorCode,@errorMessage)");
        echo $this->db->affected_rows();exit;

        if ($this->db->affected_rows() > 0) {
            $output = [
                'status' => '1',
                'Message' => 'Data Saved Succesfully',
                'Row count' => $this->db->affected_rows()
            ];
            $this->set_response($output, REST_Controller::HTTP_OK);
        } else {
            $output = [
                'status' => '0',
                'Message' => 'Failed to save Data',
                'Row count' => 0,
                'Responce' => 0,
            ];
            $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
    }
    
    

}
