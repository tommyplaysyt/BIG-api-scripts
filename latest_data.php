<?php
// Define the API URL for pets and RAP
$petsApiUrl = "https://biggamesapi.io/api/exists";
$rapApiUrl = "https://biggamesapi.io/api/rap";

// Fetch data from the Pets API
$petsResponse = file_get_contents($petsApiUrl);
$petsData = json_decode($petsResponse, true);

// Fetch data from the RAP API
$rapResponse = file_get_contents($rapApiUrl);
$rapData = json_decode($rapResponse, true);

// Check if the data was fetched successfully
if ($petsData && $rapData) {
    // Combine pet data with RAP data based on pet ID
    $combinedData = [];
    foreach ($petsData['data'] as $pet) {
        $petID = $pet['configData']['id'];
        $rapValue = 0; // Default RAP value if not found
        foreach ($rapData['data'] as $rapEntry) {
            if ($rapEntry['configData']['id'] === $petID) {
                $rapValue = $rapEntry['value'];
                break;
            }
        }
        // Calculate Market Cap
        $marketCap = $pet['value'] * $rapValue;
        $combinedData[] = [
            'PetID' => $petID,
            'PetName' => $pet['configData']['id'],
            'ExistCount' => $pet['value'],
            'Category' => determineCategory($pet['configData']),
            'RAPValue' => $rapValue,
            'MarketCap' => $marketCap
        ];
    }

    // Sort the combined data based on pet existence count
    usort($combinedData, function ($a, $b) {
        return $b['ExistCount'] - $a['ExistCount'];
    });

    // Send the combined data as JSON response
    header('Content-Type: application/json');
    echo json_encode($combinedData);
} else {
    // Return an error message if data fetching fails
    http_response_code(500);
    echo json_encode(['error' => 'Failed to fetch data from APIs.']);
}

// Function to determine the pet category based on attributes
function determineCategory($configData)
{
    $category = 'Normal';
    if (isset($configData['pt']) && $configData['pt'] == 1) {
        $category = isset($configData['sh']) && $configData['sh'] ? 'Shiny Golden' : 'Golden';
    } elseif (isset($configData['pt']) && $configData['pt'] == 2) {
        $category = isset($configData['sh']) && $configData['sh'] ? 'Shiny Rainbow' : 'Rainbow';
    } elseif (isset($configData['sh']) && $configData['sh']) {
        $category = 'Shiny';
    }
    return $category;
}
?>
