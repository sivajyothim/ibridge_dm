<?php

defined('BASEPATH') OR exit('No direct script access allowed');

class User extends MY_Controller {

    function __construct() {
        // Construct the parent class
        parent::__construct();
        $this->auth();
        $this->load->model('Main_model');
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
        } else {
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
        } else {
            $output = [
                'status' => '0',
                'Message' => 'Invalid Data Provided',
                'Row count' => 0,
                'Responce' => 0,
            ];
            $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
    }

    public function getClients_post() {
        $userId = $this->user_data->id;
//        $userdata = $this->Main_model->userdata();
        $clientId = $this->post('clientId');
        $clientName = $this->post('clientName');

        if ($userId != "") {
            $query = $this->db->query("call usp_GetClients('" . $clientId . "','" . $userId . "','" . $clientName . "',@errorCode)");
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
        } else {
            $output = [
                'status' => '0',
                'Message' => 'Invalid Data Provided',
                'Row count' => 0,
                'Responce' => 0,
            ];
            $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
    }

    public function getUsers_post() {
        $userId = $this->user_data->id;


        $clientId = $this->post('clientId');
        $userName = $this->post('userName');
        $roleId = $this->post('roleId');

        if ($userId != "") {
            $query = $this->db->query("call usp_GetUsers(" . $userId . ",'" . $clientId . "','" . $userName . "','" . $roleId . "',@errorCode)");
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
        } else {
            $output = [
                'status' => '0',
                'Message' => 'Invalid Data Provided',
                'Row count' => 0,
                'Responce' => 0,
            ];
            $this->set_response($output, REST_Controller::HTTP_BAD_REQUEST);
        }
    }

    public function manageUser_post() {
        $this->post = file_get_contents('php://input');
        if ($this->post('userId') != "") {
            $userId = $this->post('userId');
        } else {
            $userId = 0;  //As per SP
        }
        $roleId = $this->post('roleId');
        $clientId = $this->post('clientId');
        $name = $this->post('name');
        $contactNumber = $this->post('contactNumber');
        $email = $this->post('email');


        $password = randomPassword();

        $assignClientsIds = $this->post('assignClientsIds');
        $disignation = $this->post('disignation');
        $active = $this->post('active');
        $modifiedBy = $this->user_data->id;


        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_setUser('" . $userId . "','" . $roleId . "','" . $clientId . "','" . $name . "','" . $contactNumber . "','" . $email . "','" . $disignation . "','" . $password . "','" . $assignClientsIds . "','" . $active . "','" . $modifiedBy . "',@errorCode,@errorMessage);");

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
                $subject = $disignation . ' Login Credentials';
                $body = 'Dear User,<br /> Please find your ' . $disignation . ' login credentials below. <br /><br /> Username : ' . $name . '<br /> Password : ' . $password . '<br /><br />Thanks,<br />Ibridge Team';
//            $mail_result=$this->Main_model->send_email( $subject, $body, $email, '' );
                // success in DB
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

    public function manageClient_post() {
        $this->post = file_get_contents('php://input');
        if (!empty($this->post('clientId'))) {
            $clentId = $this->post('clientId');
        } else {
            $clentId = 0;
        }

        $clientName = $this->post('clientName');
        $contactNumber = $this->post('contactNo');
        $email = $this->post('email');
        $websiteUrl = $this->post('websiteURL');
        $facebookURL = $this->post('facebookURL');
        $youtubeURL = $this->post('youtubeURL');
        $instagramURL = $this->post('instagramURL');
        $twitterURL = $this->post('twitterURL');
        $pinterestURL = $this->post('pinterestURL');
        $linkedInURL = $this->post('linkedInURL');
        $active = $this->post('active');
        $serviceIdsOpted = $this->post('serviceIdsOpted');
        $userId = $this->user_data->id;



        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_SetClient('" . $clentId . "','" . $clientName . "', '" . $contactNumber . "', '" . $email . "','" . $websiteUrl . "','" . $facebookURL . "','" . $youtubeURL . "','" . $instagramURL . "','" . $twitterURL . "','" . $pinterestURL . "','" . $linkedInURL . "','" . $active . "','" . $serviceIdsOpted . "','" . $userId . "' ,@errorCode,@errorMessage);");
//        echo $this->db->last_query();exit;
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

    public function changePassword_post() {
        $this->post = file_get_contents('php://input');

        $userId = $this->post('userId');
        $oldPassword = $this->post('oldPassword');
        $newPassword = $this->post('newPassword');



        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_ChangePassword(" . $userId . ",'" . $oldPassword . "','" . $newPassword . "',@errorCode,@errorMessage);");

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

    public function CheckEMailToResetPassword_post() {
        $this->post = file_get_contents('php://input');

        $email = $this->post('email');




        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_CheckEMailToResetPassword('" . $email . "',@isEmailExists,@GUIDToResetPassword,@errorCode,@errorMessage);");
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
                if ($result[0]->IsEmailExists == 1) {
                    $subject = 'Reset Password';
                    $link = base_url() . 'reset-password/' . $result[0]->GUIDToResetPassword;
                    $body = 'Dear User,<br /> Please Click bellow link to reset password ' . $link . '<br /><br />Thanks,<br />Ibridge Team';
//            $mail_result=$this->Main_model->send_email( $subject, $body, $email, '' );
                    $message = "Email Sent with Resetpassword Link .";
                } else {
                    $message = "Email Sent with Resetpassword Link";
                }
                $output = [
                    'status' => '1',
                    'Message' => $message,
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

    public function ValidateRequestToResetPassword_post() {
        $this->post = file_get_contents('php://input');

        $GUIDToResetPassword = $this->post('GUIDToResetPassword');




        $canShowGenericErrorMessageToUser = false;
        try {
            $query = $this->db->query("call usp_ValidateRequestToResetPassword('" . $GUIDToResetPassword . "',@isValidRequest,@userId,@errorCode);");
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
                if ($result[0]->IsValidRequest == 1) {
                    $status = 1;
                    $message = "Valid Request";
                    $userId = $this->encrypt->encode($result[0]->UserId); //$this->encrypt->encode($result[0]->userId)
                } else {
                    $status = 0;
                    $message = "Invalid Request, please Reset your password Again";
                    $userId = null;
                }
                $output = [
                    'status' => $status,
                    'Message' => $message,
                    'Row count' => $this->db->affected_rows(),
                    'userId' => $userId,
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

    public function ResetPassword_post() {
        $this->post = file_get_contents('php://input');

        $userId = $this->encrypt->decode($this->post('userId'));

        $newPassword = $this->post('newPassword');


        $canShowGenericErrorMessageToUser = false;
        try {
            if ($userId == "") {
                throw new Exception('Please Provide valid user Id');
            }
            $query = $this->db->query("call usp_ResetPassword('" . $userId . "','" . $newPassword . "',@errorCode,@errorMessage);");
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

                $output = [
                    'status' => '1',
                    'Message' => "Your Password Changed Succesfully",
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

}
