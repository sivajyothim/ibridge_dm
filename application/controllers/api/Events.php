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
        if ($this->post('eventId') != "") {
            $eventId = $this->post('eventId');
        } else {
            $eventId = 0;  //As per SP
        }

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
        $isVideoUploaded = $this->post('isVideoUploaded'); //1 :data will insert to tblEventServiceData
        $videoUploadedPath = $this->post('videoUploadedPath');

        $query = $this->db->query("call usp_SetEvent('" . $eventId . "','" . $userId . "','" . $clientId . "','" . $eventName . "','" . $eventCategoryId . "','" . $startDateTime . "','" . $endDateTime . "','" . $venue . "','" . $guests . "','" . $speakers . "','" . $participants . "','" . $eventDescription . "','" . $eventStatusId . "','" . $serviceIdsOpted . "','" . $isSubmitedForDM . "','" . $eventStatusDescription . "','" . $newStartDateTime . "','" . $newEndDateTime . "','" . $isPhotoUploaded . "','" . $photoUploadedPath . "','" . $isVideoUploaded . "','" . $videoUploadedPath . "');");
        if (count($this->db->affected_rows()) > 0) {
            $output = [
                'status' => '1',
                'Message' => 'Data Saved Succesfully',
                'Row count' => count($this->db->affected_rows())
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
        $clientId = $userdata->ClientId;
        $orderByColumn = $this->post('orderByColumn');
        $orderAscDesc = $this->post('orderAscDesc');

        $pageLength = $this->post('pageLength');
        $pageIndex = $this->post('pageIndex');

        $startingRowNumber = NULL;


        $query = $this->db->query("call usp_GetEvents('" . $eventId . "','" . $eventName . "','" . $eventStatusId . "','" . $venue . "','" . $guests . "','" . $startDate_From . "','" . $startDate_To . "','" . $userId . "','" . $clientId . "','" . $orderByColumn . "','" . $orderAscDesc . "','" . $pageLength . "','" . $pageIndex . "','" . $startingRowNumber . "',@totalRows ,@errorCode);");
        $result = $query->result();

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
