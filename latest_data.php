<?php
// Set the directory path where the JSON files are stored
$directory = 'C:/Users/thoma/OneDrive/Documents/GitHub/BIG-api-scripts';

// Get all JSON files in the directory
$jsonFiles = glob("$directory/*.json");

// Sort files by modified time to get the latest one
usort($jsonFiles, function($a, $b) {
    return filemtime($b) - filemtime($a);
});

// Get the latest JSON file
$latestFile = $jsonFiles[0];

// Read and output the contents of the latest JSON file
header('Content-Type: application/json');
readfile($latestFile);
