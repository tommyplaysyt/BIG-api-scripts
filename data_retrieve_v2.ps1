# Define the API URL for pets and RAP
$petsApiUrl = "https://biggamesapi.io/api/exists"
$rapApiUrl = "https://biggamesapi.io/api/rap"

# Make a GET request to the Pets API and save the response as JSON
$petsResponse = Invoke-RestMethod -Uri $petsApiUrl -Method Get

# Check if the request to the Pets API was successful
if ($petsResponse.status -eq "ok") {
    # Filter pets whose names contain "Huge" or "Titanic" from the Pets API
    $filteredPets = $petsResponse.data | Where-Object { $_.configData.id -like "*Huge*" -or $_.configData.id -like "*Titanic*" }

    # Initialize an empty array to store pets data
    $petsData = @()

    # Initialize a hashtable to store RAP data by category
    $rapData = @{
        "Normal" = @{}
        "Golden" = @{}
        "Rainbow" = @{}
        "Shiny" = @{}
        "Shiny Golden" = @{}
        "Shiny Rainbow" = @{}
    }

    # Fetch all RAP data from the RAP API and categorize it
    try {
        $rapResponse = Invoke-RestMethod -Uri $rapApiUrl -Method Get
        foreach ($rapEntry in $rapResponse.data) {
            $category = "Normal"
            if ($rapEntry.configData.pt -eq 1) {
                if ($rapEntry.configData.sh) {
                    $category = "Shiny Golden"
                } else {
                    $category = "Golden"
                }
            } elseif ($rapEntry.configData.pt -eq 2) {
                if ($rapEntry.configData.sh) {
                    $category = "Shiny Rainbow"
                } else {
                    $category = "Rainbow"
                }
            } elseif ($rapEntry.configData.sh) {
                $category = "Shiny"
            }
            $rapData[$category][$rapEntry.configData.id] = $rapEntry.value
        }
    } catch {
        Write-Output "Error occurred while fetching RAP data: $_"
    }

    # Iterate through each filtered pet to fetch its data
    foreach ($pet in $filteredPets) {
        # Determine the correct category based on pet attributes (pt and sh)
        $category = "Normal"
        if ($pet.configData.pt -eq 1) {
            if ($pet.configData.sh) {
                $category = "Shiny Golden"
            } else {
                $category = "Golden"
            }
        } elseif ($pet.configData.pt -eq 2) {
            if ($pet.configData.sh) {
                $category = "Shiny Rainbow"
            } else {
                $category = "Rainbow"
            }
        } elseif ($pet.configData.sh) {
            $category = "Shiny"
        }

        # Construct the PetID to include variant information
        $petID = $pet.configData.id
        if ($pet.configData.pt) {
            $petID += "_PT$($pet.configData.pt)"
        }
        if ($pet.configData.sh) {
            $petID += "_SH"
        }

        # Fetch the RAP value from the cached data based on the correct category
        $rapValue = $rapData[$category][$pet.configData.id]

        # Handle cases where RAP Value is not available
        if (-not $rapValue) {
            $rapValue = 0  # Set RAP Value to 0 if it's not available
        }

        # Calculate Market Cap by multiplying Exist Count with RAP Value
        $marketCap = $pet.value * $rapValue

        # Add the pet data with correct category, RAP value, and Market Cap to the petsData array
        $petsData += [PSCustomObject]@{
            PetID = $petID
            PetName = $pet.configData.id
            ExistCount = $pet.value
            Category = $category
            RAPValue = $rapValue
            MarketCap = $marketCap
        }
    }

    # Sort pets based on their exist counts in descending order
    $sortedData = $petsData | Sort-Object -Property ExistCount -Descending

    # Convert sorted data to JSON format
    $jsonOutput = $sortedData | ConvertTo-Json

    # Get the current system time for the file name
    $currentTime = Get-Date -Format "yyyyMMdd-HHmmss"

    # Specify the output directory and JSON file name with system time
    $outputDirectory = "$env:USERPROFILE\Documents"  # Update with your desired directory path
    $outputFileName = "sorted_pets_data_$currentTime.json"
    $outputFilePath = Join-Path -Path $outputDirectory -ChildPath $outputFileName

    # Save the JSON data to the specified file path
    $jsonOutput | Set-Content -Path $outputFilePath -Force

    Write-Output "Sorted pets data with RAP values and Market Caps saved to $outputFilePath successfully."
} else {
    Write-Output "Failed to retrieve data from the Pets API. Check your connection."
}
