#!/bin/bash

# GitLab Configurations
GITLAB_URL="https://gitlab.server.site"  # Replace with your GitLab server URL
ACCESS_TOKEN="personal_access_token" # Replace with your GitLab token
GROUP_ID="4"  # Replace with your main GitLab group ID
BASE_DIR="gitlab_server"  # Root directory for cloned repositories

mkdir -p "$BASE_DIR"

# Function to clone repositories in a group
clone_group_repos() {
    local GROUP_ID=$1
    local GROUP_PATH=$2

    # Get repositories in the group
    REPOS=$(curl --silent --header "PRIVATE-TOKEN: $ACCESS_TOKEN" \
        "$GITLAB_URL/api/v4/groups/$GROUP_ID/projects?per_page=100" | \
        jq -r '.[] | .path_with_namespace + " " + .http_url_to_repo')

    # Clone each repository into its correct path
    while read -r REPO_PATH REPO_URL; do
        LOCAL_PATH="$BASE_DIR/$REPO_PATH"
        if [[ -d "$LOCAL_PATH" ]]; then
            echo "Skipping: $LOCAL_PATH (already exists)"
        else
            mkdir -p "$(dirname "$LOCAL_PATH")"
            echo "Cloning $REPO_URL into $LOCAL_PATH"
            git clone "https://oauth2:$ACCESS_TOKEN@${REPO_URL#https://}" "$LOCAL_PATH"
        fi
    done <<< "$REPOS"

    # Recursively process subgroups
    SUBGROUPS=$(curl --silent --header "PRIVATE-TOKEN: $ACCESS_TOKEN" \
        "$GITLAB_URL/api/v4/groups/$GROUP_ID/subgroups?per_page=100" | jq -r '.[] | "\(.id) \(.full_path)"')

    while read -r SUBGROUP_ID SUBGROUP_PATH; do
        clone_group_repos "$SUBGROUP_ID" "$SUBGROUP_PATH"
    done <<< "$SUBGROUPS"
}

# Start cloning from the main group
clone_group_repos "$GROUP_ID" ""
