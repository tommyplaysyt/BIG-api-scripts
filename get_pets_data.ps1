# Define the API URLs
$petsApiUrl = "https://biggamesapi.io/api/exists"
$rapApiUrl = "https://biggamesapi.io/api/rap"

# Make a GET request to the Pets API and save the response as JSON
$petsResponse = Invoke-RestMethod -Uri $petsApiUrl -Method Get

# Check if the request to the Pets API was successful
if ($petsResponse.status -eq "ok") {
    # Filter pets whose names contain "Huge" or "Titanic" from the Pets API
    $filteredPets = $petsResponse.data | Where-Object { $_.configData.id -like "*Huge*" -or $_.configData.id -like "*Titanic*" }

    # Make a GET request to the RAP API to fetch all RAP data
    $rapResponse = Invoke-RestMethod -Uri $rapApiUrl -Method Get

    # Check if the request to the RAP API was successful
    if ($rapResponse.status -eq "ok") {
        # Initialize a dictionary to store RAP values with pet IDs as keys
        $rapData = @{}

        # Store RAP data in the dictionary using pet IDs as keys
        foreach ($rapItem in $rapResponse.data) {
            $rapData[$rapItem.configData.id] = $rapItem.value
        }

        # Initialize an empty array to store pets data
        $petsData = @()

        # Iterate through each filtered pet to fetch its RAP value from the stored RAP data
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

            # Add the pet data with correct category and RAP value to the petsData array
            if ($category -ne "Normal") {
                $petName = "$category $($pet.configData.id)"
            } elseif ($pet.configData.sh) {
                $petName = "Shiny $($pet.configData.id)"
            } else {
                $petName = $pet.configData.id
            }

            if ($rapData.ContainsKey($pet.configData.id)) {
                # Add the pet data with correct category and RAP value to the petsData array
                $petsData += [PSCustomObject]@{
                    PetName = $petName
                    ExistCount = $pet.value
                    Category = $category
                    RAPValue = $rapData[$pet.configData.id]
                }
            } else {
                # Add the pet data with correct category and "No RAP Value" if RAP value is missing
                $petsData += [PSCustomObject]@{
                    PetName = $petName
                    ExistCount = $pet.value
                    Category = $category
                    RAPValue = "No RAP Value"
                }
            }
        }

        # Sort pets based on their exist counts in descending order
        $sortedData = $petsData | Sort-Object -Property ExistCount -Descending

        # Create a new Excel COM object
        $excel = New-Object -ComObject Excel.Application
        $workbook = $excel.Workbooks.Add()
        $sheet = $workbook.Worksheets.Item(1)

        # Set headers in Excel sheet
        $sheet.Cells.Item(1, 1) = "Pet Name"
        $sheet.Cells.Item(1, 2) = "Exist Count"
        $sheet.Cells.Item(1, 3) = "Category"
        $sheet.Cells.Item(1, 4) = "RAP Value"

        # Write sorted data to Excel sheet
        $row = 2
        foreach ($data in $sortedData) {
            $sheet.Cells.Item($row, 1) = $data.PetName
            $sheet.Cells.Item($row, 2) = $data.ExistCount
            $sheet.Cells.Item($row, 3) = $data.Category
            $sheet.Cells.Item($row, 4) = $data.RAPValue
            $row++
        }

        # Specify the output directory and Excel file name
        $outputDirectory = "$env:USERPROFILE\Documents"
        $outputFileName = Join-Path -Path $outputDirectory -ChildPath "sorted_pets_data_with_rap_with_fixed_columns.xlsx"

        # Save the Excel file
        $workbook.SaveAs($outputFileName)
        $workbook.Close()
        $excel.Quit()
        Remove-Variable excel, workbook, sheet

        Write-Output "Sorted pets data with RAP values written to $outputFileName successfully."
    } else {
        Write-Output "Failed to retrieve data from the RAP API."
    }
} else {
    Write-Output "Failed to retrieve data from the Pets API."
}
