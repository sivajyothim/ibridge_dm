<?php

defined('BASEPATH') OR exit('No direct script access allowed');

class Cronjobs extends MY_Controller {

    function __construct() {
        // Construct the parent class
        parent::__construct();
        $this->load->model('Main_model');
    }

    public function setEventsStatusToStarted_get() {


        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_SetEventsStatusToStarted(@errorCode,@errorMessage)");
            if (!$query) {
                $canShowGenericErrorMessageToUser = true;
                $error = $this->db->error();
                throw new Exception('Query error:' . $error['code'] . ' ' . $error['message']);
            } else {
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
                    $output = [
                        'status' => '1',
                        'Message' => 'Cron Job Succesfully',
                        'Row count' => count($result),
                        'Responce' => $result,
                    ];
                    $this->set_response($output, REST_Controller::HTTP_OK); //This is the respon if success
                }
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

    public function getCompletedEventsDataToSendNotifications_get() {


        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_GetCompletedEventsDataToSendNotifications(@errorCode)");
            if (!$query) {
                $canShowGenericErrorMessageToUser = true;
                $error = $this->db->error();
                throw new Exception('Query error:' . $error['code'] . ' ' . $error['message']);
            } else {
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
                    foreach ($result as $row) {
                        $email = $row->CoordinatorEmail;
                        $subject = ' Event  Completed';
                        $body = 'Dear ' . $row->CoordinatorName . ',<br /> Your event ' . $row->EventName . ' has succesfully completed. <br /><br />Thanks,<br />Ibridge Team';
                        $send = $this->Main_model->send_email($subject, $body, $email, '');
                    }
                    if ($send == 200) {
                        $output = [
                            'status' => '1',
                            'Message' => 'Cron Job Succesfully',
                        ];

                        $this->set_response($output, REST_Controller::HTTP_OK); //This is the respon if success 
                    } else {
                        throw new Exception('Failed to connect to mailserver');
                    }
                }
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

    public function SetEventCompletionAndNotificationSentDetails_get() {


        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_SetEventCompletionAndNotificationSentDetails(@errorCode )");
            if (!$query) {
                $canShowGenericErrorMessageToUser = true;
                $error = $this->db->error();
                throw new Exception('Query error:' . $error['code'] . ' ' . $error['message']);
            } else {
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
                    $output = [
                        'status' => '1',
                        'Message' => 'Cron job Succesfully',
                        'Row count' => count($result),
                        'Responce' => $result,
                    ];
                    $this->set_response($output, REST_Controller::HTTP_OK); //This is the respon if success
                }
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

}
