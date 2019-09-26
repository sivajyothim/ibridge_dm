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

    public function upload_files($path, $title, $files) {
//        print_r($files);exit;
        $config = array(
            'upload_path' => $path,
            'allowed_types' => 'jpg|gif|png|mp4',
            'overwrite' => 1,
        );

        $this->load->library('upload', $config);

        $images = array();

        foreach ($files['name'] as $key => $image) {
            $_FILES['images[]']['name'] = $files['name'][$key];
            $_FILES['images[]']['type'] = $files['type'][$key];
            $_FILES['images[]']['tmp_name'] = $files['tmp_name'][$key];
            $_FILES['images[]']['error'] = $files['error'][$key];
            $_FILES['images[]']['size'] = $files['size'][$key];

            $fileName = $title . '_' . $image;

            $images[] = $fileName;

            $config['file_name'] = $fileName;

            $this->upload->initialize($config);

            if ($this->upload->do_upload('images[]')) {
                $this->upload->data();
            } else {
                return false;
            }
        }

        return $images;
    }

    public function do_upload_old($userfile, $upload_path, $rename_file = 0) {
        print_r($userfile);
        exit;
        $config['upload_path'] = $upload_path;
        $config['allowed_types'] = 'jpg|pdf|jpeg|png';
        $config['max_size'] = 0;
        //$config['max_width']            = 1024;
        //$config['max_height']           = 768;
        if ($rename_file) {
            $config['file_name'] = $rename_file;
        }

        $this->load->library('upload', $config);
        //mutiple file upload code start
        foreach ($userfile['name'] as $key => $image) {
            $_FILES['image_file[]']['name'] = $userfile['name'][$key];
            $_FILES['image_file[]']['type'] = $userfile['type'][$key];
            $_FILES['image_file[]']['tmp_name'] = $userfile['tmp_name'][$key];
            $_FILES['image_file[]']['error'] = $userfile['error'][$key];
            $_FILES['image_file[]']['size'] = $userfile['size'][$key];
            $fileName = 'test' . '_' . $image;
            $images[] = $fileName;

            $this->upload->initialize($config);

            if ($this->upload->do_upload('images[]')) {
                $this->upload->data();
            } else {
                $error = array('error' => $this->upload->display_errors());

                print_r($error);
                return false;
            }
        }
        return $images;

        //mutiple file upload code end
//        if (!$this->upload->do_upload($userfile)) {
//            $error = array('error' => $this->upload->display_errors());
//            // $this->session->set_flashdata('message', $error);
//            // redirect('/document/create');
//            print_r($error);
//            exit();
//            //$this->load->view('upload_form', $error);
//        } else {
//            $data = array('upload_data' => $this->upload->data());
//            // print_r( $data['upload_data'] );
//            // exit();
//            return( $data['upload_data']['orig_name'] );
//            //$this->load->view('upload_success', $data);
//        }
    }

    //This function sends email 
    public function send_email($email_subject, $email_body, $to, $data) {
// if ( $email_template = $this->getById( EMAIL_TEMPLATE, EMAIL_TEMPLATE_NAME, $email_type ) )
// {
// $msg = $this->load->view( 'forgot.php', $data, true );
        $this->load->library('email', config_item('email_config'));
        $this->email->set_newline("\r\n");
        $this->email->from('anji.naga1@gmail.com'); // change it to yours   'dev@bluenettech.com'
        $this->email->to($to); // change it to yours rahul.deo@talentserv.co.in
        $this->email->subject($email_subject);

// $data['first_name'] = "Rahul Deo";
// $email_body = $email_template->{EMAIL_TEMPLATE_BODY};
// foreach ($data as $key => $value) {
// $email_body = str_replace("{" .$key . "}", $value, $email_body);
// }

        $this->email->message($email_body);
        if ($this->email->send()) {
            $str=200;
            return $str;
// echo 'Email sent.';
//            return true;
        } else {
            $str=500;
            return $str;
//            return $this->email->print_debugger();
//            show_error($this->email->print_debugger());
        }

// }
// else{
// return false;
// }

        return false;
    }

    //Function End
}
