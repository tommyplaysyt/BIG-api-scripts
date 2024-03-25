document.addEventListener('DOMContentLoaded', () => {
    const petSelect = document.getElementById('petSelect');
    const petInfoDiv = document.getElementById('petInfo');

    // Fetch JSON data from the local file
    fetch('pets_data.json')
        .then(response => response.json())
        .then(data => {
            // Populate the dropdown with pet names
            data.forEach(pet => {
                const option = document.createElement('option');
                option.value = pet.PetID;
                option.textContent = pet.PetName;
                petSelect.appendChild(option);
            });

            // Event listener for dropdown change
            petSelect.addEventListener('change', () => {
                const selectedPetId = petSelect.value;
                const selectedPet = data.find(pet => pet.PetID === selectedPetId);

                // Display pet information
                if (selectedPet) {
                    petInfoDiv.innerHTML = `
                        <h2>${selectedPet.PetName}</h2>
                        <p>Exist Count: ${selectedPet.ExistCount}</p>
                        <p>RAP Value: ${selectedPet.RAPValue}</p>
                        <p>Category: ${selectedPet.Category}</p>
                        <p>Market Cap: ${selectedPet.MarketCap}</p>
                    `;
                } else {
                    petInfoDiv.innerHTML = '<p>No information available for selected pet.</p>';
                }
            });
        })
        .catch(error => {
            console.error('Error fetching data:', error);
            petInfoDiv.innerHTML = '<p>Error fetching data. Please try again later.</p>';
        });
});
