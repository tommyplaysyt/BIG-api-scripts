# Define the API URL for pets and RAP
$petsApiUrl = "https://biggamesapi.io/api/exists"
$rapApiUrl = "https://biggamesapi.io/api/rap"

# V1 Deprecation warning
Write-Output "V1 uses an old logic and writes Market Cap and RAP Values to an Excel Document. Run data_retrieve_v2.ps1 for an updated version that converts combined RAP API and Exist API to a json file. (HUGES + TITANICS ONLY)"

Write-Output "Starting import request from Exist API and RAP API"
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

    # Create a new Excel COM object
    $excel = New-Object -ComObject Excel.Application
    $workbook = $excel.Workbooks.Add()
    $sheet = $workbook.Worksheets.Item(1)

    # Set headers in Excel sheet
    $sheet.Cells.Item(1, 1) = "Pet ID"
    $sheet.Cells.Item(1, 2) = "Pet Name"
    $sheet.Cells.Item(1, 3) = "Exist Count"
    $sheet.Cells.Item(1, 4) = "Category"
    $sheet.Cells.Item(1, 5) = "RAP Value"
    $sheet.Cells.Item(1, 6) = "Market Cap"  # New column for Market Cap

    # Write sorted data to Excel sheet
    $row = 2
    foreach ($data in $sortedData) {
        $sheet.Cells.Item($row, 1) = $data.PetID
        $sheet.Cells.Item($row, 2) = $data.PetName
        $sheet.Cells.Item($row, 3) = $data.ExistCount
        $sheet.Cells.Item($row, 4) = $data.Category
        $sheet.Cells.Item($row, 5) = $data.RAPValue
        $sheet.Cells.Item($row, 6) = $data.MarketCap  # Write Market Cap in the new column
        $row++
    }

    # Calculate and write the sum of Market Caps at the bottom of the sheet
    $totalMarketCapFormula = "=SUM(F2:F$row)"
    $totalMarketCapCell = $sheet.Cells.Item($row, 6)
    $totalMarketCapCell.Formula = $totalMarketCapFormula

    # Specify the output directory and Excel file name
    $outputDirectory = "$env:USERPROFILE\Documents"
    $outputFileName = Join-Path -Path $outputDirectory -ChildPath "sorted_pets_data_with_rap_and_marketcap.xlsx"

    # Save the Excel file
    $workbook.SaveAs($outputFileName)
    $workbook.Close()
    $excel.Quit()
    Remove-Variable excel, workbook, sheet

    Write-Output "Sorted pets data with RAP values and Market Caps written to $outputFileName successfully."
} else {
    Write-Output "Failed to retrieve data from the Pets API. Check your connection."
}
