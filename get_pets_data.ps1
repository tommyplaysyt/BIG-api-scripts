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

    # Initialize a hashtable to store RAP data
    $rapData = @{}

    # Fetch all RAP data from the RAP API
    try {
        $rapResponse = Invoke-RestMethod -Uri $rapApiUrl -Method Get
        $rapData = @{}
        foreach ($rapEntry in $rapResponse.data) {
            $rapData[$rapEntry.configData.id] = $rapEntry.value
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

        # Fetch the RAP value from the cached data
        $rapValue = $rapData[$pet.configData.id]

        # Add the pet data with correct category and RAP value to the petsData array
        $petsData += [PSCustomObject]@{
            PetID = $petID
            PetName = $pet.configData.id
            ExistCount = $pet.value
            Category = $category
            RAPValue = if ($rapValue) { $rapValue } else { "No RAP Value" }
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

    # Write sorted data to Excel sheet
    $row = 2
    foreach ($data in $sortedData) {
        $sheet.Cells.Item($row, 1) = $data.PetID
        $sheet.Cells.Item($row, 2) = $data.PetName
        $sheet.Cells.Item($row, 3) = $data.ExistCount
        $sheet.Cells.Item($row, 4) = $data.Category
        $sheet.Cells.Item($row, 5) = $data.RAPValue
        $row++
    }

    # Specify the output directory and Excel file name
    $outputDirectory = "$env:USERPROFILE\Documents"
    $outputFileName = Join-Path -Path $outputDirectory -ChildPath "sorted_pets_data_with_rap.xlsx"

    # Save the Excel file
    $workbook.SaveAs($outputFileName)
    $workbook.Close()
    $excel.Quit()
    Remove-Variable excel, workbook, sheet  

    Write-Output "Sorted pets data with RAP values written to $outputFileName successfully."
} else {
    Write-Output "Failed to retrieve data from the Pets API."
}
