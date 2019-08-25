<?php if(!defined('BASEPATH')) exit('No direct script allowed');

class User_model extends CI_Model{

        public function user_data($username,$password){
            $insert_data=array(
                    'username'=>$username,
                   'password'=>$password
            );
            $sql=$this->db->insert('m_user',$insert_data);
            return true;
        }

	
}