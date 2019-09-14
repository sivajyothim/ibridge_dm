<?php

defined('BASEPATH') OR exit('No direct script access allowed');

class Services extends MY_Controller {

    function __construct() {
        // Construct the parent class
        parent::__construct();
        $this->auth();
    }

    public function clientServices_post() {

//        $userdata = $this->Main_model->userdata();
        $clientId=$this->post('clientId');
        $callingFrom=$this->post('callingFrom');
        $query = $this->db->query("call usp_GetClientServices(" . $this->user_data->id . "," . $clientId . ",'".$callingFrom."',@errorCode)");
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

        $serviceId = $this->post('serviceId');
        $serviceTypeId = $this->post('serviceTypeId');
        $serviceName = $this->post('serviceName');

        $query = $this->db->query("call usp_GetServices('" . $serviceId . "','" . $serviceTypeId . "','" . $serviceName . "',@errorCode)");

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

    public function manageService_post() {
        $this->post = file_get_contents('php://input');
        if (!empty($this->post('serviceId'))) {
            $serviceId = $this->post('serviceId');
        } else {
            $serviceId = -1;
        }
        $serviceTypeId = $this->post('serviceTypeId');
        $serviceName = $this->post('serviceName');
        $active = $this->post('active');
        $userId = $this->user_data->id;
   
           
        $canShowGenericErrorMessageToUser = false;
        try 
        {
            $query = $this->db->query("call usp_SetService(" . $serviceId . "," . $serviceTypeId . ",'" . $serviceName . "'," . $userId . "," . $active . ")");

            $result=$query->result();
//            print_r($result);
//            exit;

            if(isset($result[0]->ErrorCode) && $result[0]->ErrorCode > 0){
                if($result[0]->ErrorCode == 45000)
                {
                    // error in DB - CUSTOM MESSAGE
                    throw new Exception(substr($result[0]->ErrorMessage, strpos($result[0]->ErrorMessage, ":") + 1)); 
                }
                else
                {
                    // error in DB - Generic Message
                    $canShowGenericErrorMessageToUser = true;
                    throw new Exception($result[0]->ErrorMessage); 
                }
            }
            else
            {
                // success in DB
                $output = [
                    'status' => '1',
                    'Message' => 'Data Saved Succesfully',
                    'Row count' => $this->db->affected_rows(),

                ];
                $this->set_response($output, REST_Controller::HTTP_OK);
            }
        }
        catch (Exception $e)
        {
             
            log_message('error', 'Database:'.$e->getMessage());
            
            $output = [
                    'status' => '0',
                    'Message' => $canShowGenericErrorMessageToUser == true ? GENERIC_ERROR_MESSAGE : $e->getMessage(),
                    'Row count' => 0,
                    'Responce' => 0,
                ];
                $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
    }
    
    
   

}
