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

}
