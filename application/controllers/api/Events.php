<?php

defined('BASEPATH') OR exit('No direct script access allowed');

class Events extends MY_Controller {

    function __construct() {
        // Construct the parent class
        parent::__construct();
        $this->auth();
    }

    public function eventCategories_get() {

        $query = $this->db->query("call usp_GetEventCategories()");
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

    public function manageEvent_post() {
        $this->post = file_get_contents('php://input');
        if ($this->post('eventId') != "") {
            $eventId = $this->post('eventId');
        } else {
            $eventId = 0;  //As per SP
        }
        $photoUploadedPath = $vedioUploadedPath = "";
        /* INSERT INTO tblEvents */
        $userId = $this->user_data->id;

        $userdata = $this->Main_model->userdata();
        $clientId = $userdata->ClientId;

        $eventName = $this->post('eventName');
        $eventCategoryId = $this->post('eventCategoryId');
        $startDateTime = $this->post('startDateTime');
        $endDateTime = $this->post('endDateTime');
        $venue = $this->post('venue');
        $guests = $this->post('guests');
        $speakers = $this->post('speakers');
        $participants = $this->post('participants');
        $eventDescription = $this->post('eventDescription');
        $eventStatusId = $this->post('eventStatusId');


        /* COMMA SEPERATED SERVICES IDs WITHOUT SPACES IN BETWEEN (inserted to TEMPORARY TABLE tmpTblServicesOpted) */
        $serviceIdsOpted = $this->post('serviceIdsOpted');

        $isSubmitedForDM = $this->post('isSubmitedForDM');
        $eventStatusDescription = $this->post('eventStatusDescription');

        /* when event is postponed */
        $newStartDateTime = $this->post('newStartDateTime');
        $newEndDateTime = $this->post('newEndDateTime ');

        $isPhotoUploaded = $this->post('isPhotoUploaded'); //1 :data will insert to tblEventServiceData
         $photoUploadedPath = $this->post('photoUploadedPath');
         


        if ($eventId != 0) {
            $serviceoptedarr = explode(',', $serviceIdsOpted);
            if (count($serviceoptedarr) > 0) {
                foreach ($serviceoptedarr as $service_id) {
                    $photoUploadedPath_own = "uploads/client_" . sprintf("%02d", $clientId) . "/event_" . sprintf("%02d", $eventId) . "/service_" . sprintf("%02d", $service_id) . "" . '/';
                    if (!is_dir($photoUploadedPath_own)) {
                        @mkdir($photoUploadedPath_own, 0777, TRUE);
                    }
                }
            }
        }
        

        $isVideoUploaded = $this->post('isVideoUploaded'); //1 :data will insert to tblEventServiceData
        $videoUploadedPath = $this->post('videoUploadedPath');


        $vedioServiceId = $this->post('vedioUploadedServiceId');

        $query = $this->db->simple_query("call usp_SetEvent('" . $eventId . "','" . $userId . "','" . $clientId . "','" . $eventName . "','" . $eventCategoryId . "','" . $startDateTime . "','" . $endDateTime . "','" . $venue . "','" . $guests . "','" . $speakers . "','" . $participants . "','" . $eventDescription . "','" . $eventStatusId . "','" . $serviceIdsOpted . "','" . $isSubmitedForDM . "','" . $eventStatusDescription . "','" . $newStartDateTime . "','" . $newEndDateTime . "','" . $photoUploadedPath . "','" . $videoUploadedPath . "',@errorCode);");
//echo $this->db->last_query();exit;
        if ($this->db->affected_rows() > 0) {
            $output = [
                'status' => '1',
                'Message' => 'Data Saved Succesfully',
//                'Row count' => $this->db->affected_rows()
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

    public function eventStatus_get() {

        $query = $this->db->query("call usp_GetEventStatusList(@errorCode )");
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

    public function eventNamesAjax_post() {
        $this->post = file_get_contents('php://input');
        $event_name = $this->post('eventName');


        $userdata = $this->Main_model->userdata();

        $query = $this->db->query("call usp_GetEventNamesForAjaxSearch('" . $event_name . "'," . $userdata->ClientId . ",@errorCode)");
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

    public function eventSummary_get() {

        $userdata = $this->Main_model->userdata();
        $query = $this->db->query("call usp_GetEventsSummary(" . $this->user_data->id . "," . $userdata->ClientId . ",@errorCode)");
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

    public function getEvent_post() {
        $this->post = file_get_contents('php://input');
        if ($this->post('eventId') != "") {
            $eventId = $this->post('eventId');
        } else {
            $eventId = 0;  //As per SP
        }
        $eventName = $this->post('eventName');
        $eventStatusId = $this->post('eventStatusId');
        $venue = $this->post('venue');
        $guests = $this->post('guests');
        $startDate_From = $this->post('startDate_From');
        $startDate_To = $this->post('startDate_To');

        $userId = $this->user_data->id;

        $userdata = $this->Main_model->userdata();
        $clientId = $this->post('clientId');
        $orderByColumn = $this->post('orderByColumn');
        $orderAscDesc = $this->post('orderAscDesc');

        $pageLength = $this->post('pageLength');
        $pageIndex = $this->post('pageIndex');

        $startingRowNumber = NULL;
        $dMCompletedBy = $this->post('dMCompletedBy');
        $callingFrom = $userdata->RoleCode;

        $query1 = $this->db->query("call usp_GetEvents('" . $eventId . "','" . $eventName . "','" . $eventStatusId . "','" . $venue . "','" . $guests . "','" . $startDate_From . "','" . $startDate_To . "','" . $userId . "','" . $clientId . "','" . $orderByColumn . "','" . $dMCompletedBy . "','" . $callingFrom . "','" . $orderAscDesc . "','" . $pageLength . "','" . $pageIndex . "','" . $startingRowNumber . "',@totalRows ,@errorCode);");
        $query2 = $this->db->query("call usp_GetEvents('" . $eventId . "','" . $eventName . "','" . $eventStatusId . "','" . $venue . "','" . $guests . "','" . $startDate_From . "','" . $startDate_To . "','" . $userId . "','" . $clientId . "','" . $orderByColumn . "','" . $dMCompletedBy . "','" . $callingFrom . "','" . $orderAscDesc . "','" . $pageLength . "','" . $pageIndex . "','" . $startingRowNumber . "',@totalRows ,@errorCode);");
        $result1 = $query1->result();
        $result2 = $query2->result();
        $result = array_merge($result1, $result2);
//        print_r($this->db->last_query());exit;
        if ($result > 0) {
            $output = [
                'status' => '1',
                'Message' => 'Data Retrived Succesfully',
                'Row count' => count($result),
                'Responce' => ['event_data' => $result1, 'service_data' => $result2],
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

    public function dmmanageEvent_post() {
        $this->post = file_get_contents('php://input');

        $eventId = $this->post('eventId');


        $userdata = $this->Main_model->userdata();
        $clientId = $this->post('clientId');
        $eventStatusId = $this->post('eventStatusId');
        $eventServiceIdsAndData = $this->post('eventServiceIdsAndData'); //1~@~2~@~dmcheck#@#1~@~3~@~dmcheck

//        $isPhotoUploaded = $this->post('isPhotoUploaded'); //1 :data will insert to tblEventServiceData
//        $photoUploadedPath = $this->post('photoUploadedPath');
//        $isVideoUploaded = $this->post('isVideoUploaded'); //1 :data will insert to tblEventServiceData
//        $videoUploadedPath = $this->post('videoUploadedPath');

        $eventName = $this->post('eventName');
        $eventCategoryId = $this->post('eventCategoryId');
        $startDateTime = $this->post('startDateTime');
        $endDateTime = $this->post('endDateTime');
        $venue = $this->post('venue');
        $guests = $this->post('guests');
        $speakers = $this->post('speakers');
        $participants = $this->post('participants');
        $eventDescription = $this->post('eventDescription');

        $isDMCompleted = $this->post('isDMCompleted');
        $DMComments = $this->post('DMComments');
        $isEventLockReleased = $this->post('isEventLockReleased');
        $eventLockReleaseReason = $this->post('eventLockReleaseReason');


        $userId = $this->user_data->id;
        //codeforphoto upload
        $str = "1~@~2~@~dmcheck#@#1~@~3~@~dmcheck";


        foreach (explode("#@#", $str) as $row) {

//            print_r(explode("~@~", $row));
        }
        
//            print_r($_FILES['images_7']);
//            exit;
//           echo count($_FILES['image_file']['name']);exit;
            $photoUploadedPath=[];
            $i=0;
            foreach ($_FILES as $file_name => $val) {
                $serviceid_from_image = substr($file_name, strpos($file_name, "_") + 1);

                if (!empty($val['name'][0])) {
                    $photoUploadedPath[$i] = "uploads/client_" . sprintf("%02d", $clientId) . "/event_" . sprintf("%02d", $eventId) . "/service_" . sprintf("%02d", $serviceid_from_image) . "" . '/';
                    if (!is_dir($photoUploadedPath[$i])) {
                        @mkdir($photoUploadedPath[$i], 0777, TRUE);
                    }
                    $title = url_title('image_' . time(), 'dash', TRUE);
                    if ($this->Main_model->upload_files($photoUploadedPath[$i], $title, $val) === FALSE) {
                        $data['error'] = $this->upload->display_errors();
                        print_r($data['error']);
                        exit;
                    }
                }
            $i++; }
                    
            $photoUploadedPath=implode(',',$photoUploadedPath);
                       

        
//        exit;
        //code end
        $query = $this->db->simple_query("call usp_SetEventByDMExecutive('" . $eventId . "','" . $clientId . "','" . $eventStatusId . "','" . $eventServiceIdsAndData . "','" . $eventName . "','" . $eventCategoryId . "','" . $startDateTime . "','" . $endDateTime . "','" . $venue . "','" . $guests . "','" . $speakers . "','" . $participants . "','" . $eventDescription . "','" . $isDMCompleted . "','" . $DMComments . "','" . $isEventLockReleased . "','" . $eventLockReleaseReason . "','" . $userId . "',@errorCode);");
//$this->db->last_query();exit;
//        print_r($this->db->affected_rows());exit;
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

    public function getCompletedEvents_get() {

        $query = $this->db->query("call usp_GetCompletedEventsDataToSendNotifications(@errorCode)");
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

    public function GetEventDataForReport_get() {

        $userdata = $this->Main_model->userdata();
        $query = $this->db->query("call usp_GetEventDataForReport('" . $userdata->ClientId . "',@errorCode)");
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
