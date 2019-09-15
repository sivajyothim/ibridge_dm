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

        $eventId = GetNumericData($this->post('eventId'));
        $photoUploadedPath = $vedioUploadedPath = "";
        /* INSERT INTO tblEvents */
        $userId = $this->user_data->id;

//        $userdata = $this->Main_model->userdata();
        $clientId = GetNumericData($this->post('clientId'));

        $eventName = $this->post('eventName');
        $eventCategoryId = GetNumericData($this->post('eventCategoryId'));
        $startDateTime = $this->post('startDateTime');
        $endDateTime = $this->post('endDateTime');
        $venue = $this->post('venue');
        $guests = $this->post('guests');
        $speakers = $this->post('speakers');
        $participants = $this->post('participants');
        $eventDescription = $this->post('eventDescription');
        $eventStatusId = GetNumericData($this->post('eventStatusId'));


        /* COMMA SEPERATED SERVICES IDs WITHOUT SPACES IN BETWEEN (inserted to TEMPORARY TABLE tmpTblServicesOpted) */
        $serviceIdsOpted = $this->post('serviceIdsOpted');

        $isSubmitedForDM = GetNumericData($this->post('isSubmitedForDM'));
        $eventStatusDescription = $this->post('eventStatusDescription');

        /* when event is postponed */
        $newStartDateTime = $this->post('newStartDateTime');
        $newEndDateTime = $this->post('newEndDateTime');

//        $isPhotoUploaded = $this->post('isPhotoUploaded'); //1 :data will insert to tblEventServiceData
        $photoUploadedPath = $this->post('photoUploadedPath');






//        $isVideoUploaded = $this->post('isVideoUploaded'); //1 :data will insert to tblEventServiceData
        $videoUploadedPath = $this->post('videoUploadedPath');


        $vedioServiceId = GetNumericData($this->post('vedioUploadedServiceId'));

        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_SetEvent(" . $eventId . ",'" . $userId . "'," . $clientId . ",'" . $eventName . "'," . $eventCategoryId . ",'" . $startDateTime . "','" . $endDateTime . "','" . $venue . "','" . $guests . "','" . $speakers . "','" . $participants . "','" . $eventDescription . "'," . $eventStatusId . ",'" . $serviceIdsOpted . "'," . $isSubmitedForDM . ",'" . $eventStatusDescription . "','" . $newStartDateTime . "','" . $newEndDateTime . "','" . $photoUploadedPath . "','" . $videoUploadedPath . "',@errorCode,@errorMessage);");
//            echo $this->db->last_query();exit;
            $result = $query->result();

            if (isset($result[0]->ErrorCode) && $result[0]->ErrorCode > 0) {
                if ($result[0]->ErrorCode == 45000) {
                    // error in DB - CUSTOM MESSAGE
                    throw new Exception(substr($result[0]->ErrorMessage, strpos($result[0]->ErrorMessage, ":") + 1));
                } else {
                    // error in DB - Generic Message
                    $canShowGenericErrorMessageToUser = true;
                    throw new Exception($result[0]->ErrorMessage);
                }
            } else {
                // success in DB
                $insertedEventid = $result[0]->EventId;
                if ($insertedEventid != "") {
                    $serviceoptedarr = explode(',', $serviceIdsOpted);
                    if (count($serviceoptedarr) > 0) {
                        foreach ($serviceoptedarr as $service_id) {
                            $photoUploadedPath_own = "uploads/client_" . sprintf("%02d", $clientId) . "/event_" . sprintf("%02d", $insertedEventid) . "/service_" . sprintf("%02d", $service_id) . "" . '/';
                            if (!is_dir($photoUploadedPath_own)) {
                                @mkdir($photoUploadedPath_own, 0777, TRUE);
                            }
                        }
                    }
                }
                $output = [
                    'status' => '1',
                    'Message' => 'Data Saved Succesfully',
                    'Row count' => $this->db->affected_rows(),
                ];
                $this->set_response($output, REST_Controller::HTTP_OK);
            }
        } catch (Exception $e) {

            log_message('error', 'Database:' . $e->getMessage());

            $output = [
                'status' => '0',
                'Message' => $canShowGenericErrorMessageToUser == true ? GENERIC_ERROR_MESSAGE : $e->getMessage(),
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


//        $userdata = $this->Main_model->userdata();
        $clientId=GetNumericData($this->post('clientId'));
        $query = $this->db->query("call usp_GetEventNamesForAjaxSearch('" . $event_name . "'," . $clientId . ",@errorCode)");
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

    public function eventSummary_post() {

//        $userdata = $this->Main_model->userdata();
        $clientId=GetNumericData($this->post('clientId'));
        $query = $this->db->query("call usp_GetEventsSummary(" . $this->user_data->id . "," . $clientId . ",@errorCode)");
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

        $eventId=GetNumericData($this->post('eventId'));
        $eventName = $this->post('eventName');
        $eventStatusId = GetNumericData($this->post('eventStatusId'));
        $venue = $this->post('venue');
        $guests = $this->post('guests');
        $startDate_From = $this->post('startDate_From');
        $startDate_To = $this->post('startDate_To');

        $userId = GetNumericData($this->user_data->id);

//        $userdata = $this->Main_model->userdata();
        $clientId = GetNumericData($this->post('clientId'));
        $orderByColumn = GetNumericData($this->post('orderByColumn'));
        $orderAscDesc = GetNumericData($this->post('orderAscDesc'));

        $pageLength = GetNumericData($this->post('pageLength'));
        $pageIndex = GetNumericData($this->post('pageIndex'));

        $startingRowNumber = 1;
        $dMCompletedBy = GetNumericData($this->post('dMCompletedBy'));
        $callingFrom = GetNumericData($this->post('callingFrom'));

        $query = $this->db->query("call usp_GetEvents(" . $eventId . ",'" . $eventName . "'," . $eventStatusId . ",'" . $venue . "','" . $guests . "','" . $startDate_From . "','" . $startDate_To . "'," . $userId . "," . $clientId . "," . $dMCompletedBy . "," . $callingFrom . "," . $orderByColumn . "," . $orderAscDesc . "," . $pageLength . "," . $pageIndex . "," . $startingRowNumber . ",@totalRows ,@errorCode);");
        $result = $query->result();
//        print_r($result);exit;
//        print_r($this->db->last_query());exit;
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
    
    public function getEventServices_post() {
        $this->post = file_get_contents('php://input');
            
        $eventId = GetNumericData($this->post('eventId'));
        $userId = $this->user_data->id;

//        $userdata = $this->Main_model->userdata();
        $clientId = GetNumericData($this->post('clientId'));
       
        $callingFrom = GetNumericData($this->post('callingFrom'));

        $query = $this->db->query("call usp_GetEventServices(" . $eventId . "," . $userId . "," . $clientId . "," . $callingFrom . ",@errorCode);");
        $result = $query->result();
//        print_r($this->db->last_query());exit;
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
    
    
    public function getEventReleaseReasons_post() {
        $this->post = file_get_contents('php://input');
      
       
        $eventId = GetNumericData($this->post('eventId'));
        $userId = $this->user_data->id;

       
        $callingFrom = GetNumericData($this->post('callingFrom'));

        $query = $this->db->query("call usp_GetEventReleaseReasons(" . $eventId . "," . $userId . "," . $callingFrom . ",@errorCode);");
        $result = $query->result();
//        print_r($this->db->last_query());exit;
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

    public function dmmanageEvent_post() {
        $this->post = file_get_contents('php://input');

        $eventId = GetNumericData($this->post('eventId'));


//        $userdata = $this->Main_model->userdata();
        $clientId = GetNumericData($this->post('clientId'));
        $eventStatusId = GetNumericData($this->post('eventStatusId'));
        $eventServiceIdsAndData = $this->post('eventServiceIdsAndData'); //1~@~2~@~dmcheck#@#1~@~3~@~dmcheck

        $eventName = $this->post('eventName');
        $eventCategoryId = GetNumericData($this->post('eventCategoryId'));
        $startDateTime = $this->post('startDateTime');
        $endDateTime = $this->post('endDateTime');
        $venue = $this->post('venue');
        $guests = $this->post('guests');
        $speakers = $this->post('speakers');
        $participants = $this->post('participants');
        $eventDescription = $this->post('eventDescription');

        $isDMCompleted = GetNumericData($this->post('isDMCompleted'));
        $DMComments = $this->post('DMComments');
        $isEventLockReleased = GetNumericData($this->post('isEventLockReleased'));
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
//        $photoUploadedPath = implode(',', $photoUploadedPath);
//        exit;
        //code end
        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_SetEventByDMExecutive(" . $eventId . "," . $clientId . "," . $eventStatusId . ",'" . trim($eventServiceIdsAndData) . "','" . $eventName . "'," . $eventCategoryId . ",'" . $startDateTime . "','" . $endDateTime . "','" . $venue . "','" . $guests . "','" . $speakers . "','" . $participants . "','" . $eventDescription . "'," . $isDMCompleted . ",'" . $DMComments . "'," . $isEventLockReleased . ",'" . $eventLockReleaseReason . "'," . $userId . ",@errorCode,@errorMessage);");
//            echo $this->db->last_query();exit;
            $result = $query->result();
//            print_r($result);
//            exit;

            if (isset($result[0]->ErrorCode) && $result[0]->ErrorCode > 0) {
                if ($result[0]->ErrorCode == 45000) {
                    // error in DB - CUSTOM MESSAGE
                    throw new Exception(substr($result[0]->ErrorMessage, strpos($result[0]->ErrorMessage, ":") + 1));
                } else {
                    // error in DB - Generic Message
                    $canShowGenericErrorMessageToUser = true;
                    throw new Exception($result[0]->ErrorMessage);
                }
            } else {
                // success in DB
                //immage upload start
                $photoUploadedPath = [];
                $i = 0;
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
                    $i++;
                }
                //image upload end
                $output = [
                    'status' => '1',
                    'Message' => 'Data Saved Succesfully',
                    'Row count' => $this->db->affected_rows(),
                ];
                $this->set_response($output, REST_Controller::HTTP_OK);
            }
        } catch (Exception $e) {

            log_message('error', 'Database:' . $e->getMessage());

            $output = [
                'status' => '0',
                'Message' => $canShowGenericErrorMessageToUser == true ? GENERIC_ERROR_MESSAGE : $e->getMessage(),
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

    public function GetEventDataForReport_post() {

//        $userdata = $this->Main_model->userdata();
        $eventId=GetNumericData($this->post('eventId'));
        $query = $this->db->query("call usp_GetEventDataForReport(" . $eventId . ",@errorCode)");
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
    public function GetEventServiceDataForReport_post() {

//        $userdata = $this->Main_model->userdata();
        $eventId=GetNumericData($this->post('eventId'));
        $query = $this->db->query("call usp_GetEventServiceDataForReport(" . $eventId . "s,@errorCode)");
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
    public function GetEventReleaseDataForReport_post() {

//        $userdata = $this->Main_model->userdata();
        $eventId=GetNumericData($this->post('eventId'));
        $query = $this->db->query("call usp_GetEventReleaseDataForReport(" . $eventId . ",@errorCode)");
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
