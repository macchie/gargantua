function user_add_sudo {
    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPASS" ]; then
        echo "No new username and/or password entered"
        return 1;
    fi

    # adduser $USERNAME --disabled-password --gecos ""
    echo "$USERNAME:$USERPASS"
    # usermod -aG sudo $USERNAME
}

user_add_sudo
