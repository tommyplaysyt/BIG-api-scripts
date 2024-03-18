# Define the API URLs
$petsApiUrl = "https://biggamesapi.io/api/exists"
$rapApiUrl = "https://biggamesapi.io/api/rap"

# Make a GET request to the Pets API and save the response as JSON
$petsResponse = Invoke-RestMethod -Uri $petsApiUrl -Method Get

# Make a GET request to the RAP API and save the response as JSON
$rapResponse = Invoke-RestMethod -Uri $rapApiUrl -Method Get

# Check if both requests were successful
if ($petsResponse.status -eq "ok" -and $rapResponse.status -eq "ok") {
    # Filter pets whose names contain "Huge" or "Titanic" from the Pets API
    $filteredPets = $petsResponse.data | Where-Object { $_.configData.id -like "*Huge*" -or $_.configData.id -like "*Titanic*" }

    # Extract the exist counts of filtered pets and categorize them
    $petsData = $filteredPets | ForEach-Object { 
        [PSCustomObject]@{ 
            PetID = $_.configData.id
            ExistCount = $_.value
            Category = if ($_.configData.pt -eq 1) { "Golden" }
                       elseif ($_.configData.pt -eq 2) { "Rainbow" }
                       elseif ($_.configData.sh -and $_.configData.pt -eq 1) { "Shiny Golden" }
                       elseif ($_.configData.sh -and $_.configData.pt -eq 2) { "Shiny Rainbow" }
                       else { "Normal" }
            RAPValue = ($rapResponse.data | Where-Object { $_.configData.id -eq $_.configData.id }).value
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
    $sheet.Cells.Item(1, 2) = "Exist Count"
    $sheet.Cells.Item(1, 3) = "Category"
    $sheet.Cells.Item(1, 4) = "RAP Value"

    # Write sorted data to Excel sheet
    $row = 2
    foreach ($data in $sortedData) {
        $sheet.Cells.Item($row, 1) = $data.PetID
        $sheet.Cells.Item($row, 2) = $data.ExistCount
        $sheet.Cells.Item($row, 3) = $data.Category
        $sheet.Cells.Item($row, 4) = $data.RAPValue
        $row++
    }

    # Specify the output directory and Excel file name
    $outputDirectory = "$env:USERPROFILE\Documents"
    $outputFileName = Join-Path -Path $outputDirectory -ChildPath "sorted_pets_data.xlsx"

    # Save the Excel file
    $workbook.SaveAs($outputFileName)
    $workbook.Close()
    $excel.Quit()
    Remove-Variable excel, workbook, sheet

    Write-Output "Sorted pets data written to $outputFileName successfully."
} else {
    Write-Output "Failed to retrieve data from one or both APIs."
}
