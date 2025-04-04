
# Wachtwoorden uitschakelen voor beheerder
echo "beheerder ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-beheerder
sudo chmod 440 /etc/sudoers.d/99-beheerder