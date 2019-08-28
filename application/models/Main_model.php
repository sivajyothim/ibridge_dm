<?php

if (!defined('BASEPATH'))
    exit('No direct script allowed');

class Main_model extends CI_Model {

    function __construct() {
        // Construct the parent class
        parent::__construct();
    }

    public function userdata() {
        $query = $this->db->query("call usp_GetUserRoleClientDetails('" . $this->user_data->id . "')");
        $result = $query->row();
        return $result;
    }

}
