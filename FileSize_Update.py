import os
import subprocess
import getpass

def prompt_password(prompt_message):
    return getpass.getpass(prompt_message)

def update_db_password():
    # Run 'pwd' to display the current working directory
    current_directory = subprocess.run(['pwd'], capture_output=True, text=True).stdout.strip()
    print(f"Current directory: {current_directory}")

    # Prompt for the path to the .env file
    env_dir_path = input("Enter the path to the directory containing the .env file (e.g., /immich-app): ")

    # Construct the full path to the .env file
    env_file_path = os.path.join(env_dir_path, ".env")

    # Check if the file exists
    if not os.path.isfile(env_file_path):
        print(f"File not found: {env_file_path}")
        exit(1)

    # Prompt for new password and confirmation
    new_password = prompt_password("Enter the new DB password: ")
    confirm_password = prompt_password("Confirm the new DB password: ")

    # Check if passwords match
    if new_password != confirm_password:
        print("Passwords do not match. Please try again.")
        exit(1)

    # Read the .env file
    with open(env_file_path, 'r') as file:
        lines = file.readlines()

    # Update the .env file with the new password
    updated = False
    with open(env_file_path, 'w') as file:
        for line in lines:
            if line.startswith("DB_PASSWORD="):
                file.write(f"DB_PASSWORD={new_password}\n")
                updated = True
            else:
                file.write(line)

    if updated:
        print("DB password updated successfully.")
    else:
        print("DB_PASSWORD entry not found in the .env file.")
        exit(1)

def add_nginx_config_line():
    # Define the path to the nginx.conf file
    nginx_conf_path = "/etc/nginx/nginx.conf"

    # Check if the file exists
    if not os.path.isfile(nginx_conf_path):
        print(f"File not found: {nginx_conf_path}")
        exit(1)

    # Read the nginx.conf file
    with open(nginx_conf_path, 'r') as file:
        lines = file.readlines()

    # Flag to check if the line was added
    line_added = False

    # Prepare the new line to be added
    new_line = "\tclient_max_body_size 500M;\n"

    # Open the nginx.conf file for writing
    with open(nginx_conf_path, 'w') as file:
        for line in lines:
            file.write(line)
            # Add the new line after the line containing "types_hash_max_size:"
            if "types_hash_max_size" in line and not line_added:
                indentation = line[:len(line) - len(line.lstrip())]  # Capture the indentation of the current line
                file.write(f"{indentation}client_max_body_size 500M;\n")
                line_added = True

    if line_added:
        print("Configuration line added successfully.")
    else:
        print("The specified line was not found in the configuration file.")
        exit(1)

if __name__ == "__main__":
    update_db_password()
    add_nginx_config_line()

