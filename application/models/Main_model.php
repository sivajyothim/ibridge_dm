<?php

if (!defined('BASEPATH'))
    exit('No direct script allowed');

class Main_model extends CI_Model {

    function __construct() {
        // Construct the parent class
        parent::__construct();
    }

    public function userdata() {
        $query = $this->db->query("call usp_GetUserRoleClientDetails('" . $this->user_data->id . "',@errorCode)");
        $result = $query->row();
        return $result;
    }

    public function do_upload($userfile, $upload_path, $rename_file = 0) {
//            echo $upload_path;exit;
        $config['upload_path'] = $upload_path;
        $config['allowed_types'] = 'jpg|pdf|jpeg|png';
        $config['max_size'] = 0;
        //$config['max_width']            = 1024;
        //$config['max_height']           = 768;
        if ($rename_file) {
            $config['file_name'] = $rename_file;
        }

        $this->load->library('upload', $config);

        if (!$this->upload->do_upload($userfile)) {
            $error = array('error' => $this->upload->display_errors());
            // $this->session->set_flashdata('message', $error);
            // redirect('/document/create');
            print_r($error);
            exit();
            //$this->load->view('upload_form', $error);
        } else {
            $data = array('upload_data' => $this->upload->data());
            // print_r( $data['upload_data'] );
            // exit();
            return( $data['upload_data']['orig_name'] );
            //$this->load->view('upload_success', $data);
        }
    }

    //This function sends email 
    public function send_email($email_type, $to, $data) {
        if ($email_template = $this->getById(EMAIL_TEMPLATE, EMAIL_TEMPLATE_NAME, $email_type)) {

            // $msg = $this->load->view( 'forgot.php', $data, true );
            $this->load->library('email', config_item('email_config'));
            $this->email->set_newline("\r\n");
            $this->email->from('nap.support@bluenettech.com'); // change it to yours
            $this->email->to($to); // change it to yours rahul.deo@talentserv.co.in
            $this->email->subject($email_template->{EMAIL_TEMPLATE_SUBJECT});

            // $data['first_name'] = "Rahul Deo";
            $email_body = $email_template->{EMAIL_TEMPLATE_BODY};

            foreach ($data as $key => $value) {
                $email_body = str_replace("{" . $key . "}", $value, $email_body);
            }

            $this->email->message($email_body);
            if ($this->email->send()) {
//				echo 'Email sent.';
                return true;
            } else {
                show_error($this->email->print_debugger());
            }
        } else {
            return false;
        }

        return false;
    }

    //Function End
}
