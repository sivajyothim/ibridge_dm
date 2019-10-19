<?php

defined('BASEPATH') OR exit('No direct script access allowed');

function randomPassword() {
    $alphabet = "abcdefghijklmnopqrstuwxyzABCDEFGHIJKLMNOPQRSTUWXYZ0123456789";
    $pass = array(); //remember to declare $pass as an array
    $alphaLength = strlen($alphabet) - 1; //put the length -1 in cache
    for ($i = 0; $i < 8; $i++) {
        $n = rand(0, $alphaLength);
        $pass[] = $alphabet[$n];
    }
    return implode($pass); //turn the array into a string
}

function search_revisions($dataArray, $search_value, $key_to_search, $other_matching_value = null, $other_matching_key = null) {
// This function will search the revisions for a certain value
    // related to the associative key you are looking for.
    $keys = array();
    foreach ($dataArray as $key => $cur_value) {
        if ($cur_value[$key_to_search] == $search_value) {
            if (isset($other_matching_key) && isset($other_matching_value)) {
                if ($cur_value[$other_matching_key] == $other_matching_value) {
                    $keys[] = $key;
                }
            } else {
                // I must keep in mind that some searches may have multiple
                // matches and others would not, so leave it open with no continues.
                $keys[] = $key;
            }
        }
    }
    return $keys;
}

function GetNumericData($value) {
    $returnVal = "NULL";
    if (trim($value) != "") {
        $returnVal = (int) ($value);
    }
    return $returnVal;
}

function convert_utc_time($datetime) {

//    $datetime = "2019-09-29 18:00:00";
    $datetime = date("y-m-d h:i:s", strtotime($datetime));
    $given = new DateTime($datetime, new DateTimeZone("Asia/Kolkata"));
    $given->setTimezone(new DateTimeZone("UTC"));
    $output = $given->format("Y-m-d h:i:s");
    return $output;
}

function utcToConvertTime() {
    
}
