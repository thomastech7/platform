#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

REGISTRY_TARGET="thanhnm777/hce-test"

echo "Finding all hardcoreeng/* docker images..."

# Get all hardcoreeng/ images, parse their repository name and tag.
# Exclude '<none>' tags.
docker images --format "{{.Repository}}:{{.Tag}}" | grep "^hardcoreeng/" | while read -r image; do
    # e.g., hardcoreeng/account:v0.7.423
    
    # Extract tag
    tag="${image#*:}"
    
    # Extract full repository name (e.g. hardcoreeng/account)
    repo="${image%:*}"
    
    # Extract service name (e.g. account)
    service_name="${repo#hardcoreeng/}"
    
    # Skip invalid/none tags
    if [ "$tag" = "<none>" ] || [ -z "$tag" ]; then
        echo "Skipping image with no tag: $image"
        continue
    fi
    
    target_tag="${service_name}-${tag}"
    target_image="${REGISTRY_TARGET}:${target_tag}"
    
    echo "--------------------------------------------------"
    echo "Found local image: $image"
    echo "Tagging as:        $target_image"
    
    docker tag "$image" "$target_image"
    
    echo "Pushing:           $target_image..."
    docker push "$target_image"
done

echo "Done!"
