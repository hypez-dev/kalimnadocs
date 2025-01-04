#!/bin/bash

# Check if required tools are installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it first."
    exit 1
fi

if ! command -v parallel &> /dev/null; then
    echo "Error: GNU Parallel is not installed. Please install it first."
    exit 1
fi

# Configuration
CHATWOOT_BASE_URL="https://app.chatwoot.com/api/v1"
ACCOUNT_ID="101388"
API_TOKEN="mG8MhbKukji1u6RzLt2Ex7WG"
MAX_PARALLEL_JOBS=20  # Adjust based on your system capabilities
TEST_MODE=false  # Set to false to process all conversations
MAX_TEST_CONVERSATIONS=3  # Number of conversations to process in test mode

# Output file
OUTPUT_FILE="chatwoot_knowledge_base.txt"
> "$OUTPUT_FILE"  # Clear the file
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR"

# Function to fetch and process a single conversation
process_conversation() {
    local conversation_id=$1
    local temp_file="$TEMP_DIR/$conversation_id.txt"
    local messages_file="$TEMP_DIR/$conversation_id.messages.txt"
    local response
    local before_id=""

    echo "Processing conversation ID: $conversation_id"
    
    # Write conversation ID to temp file
    echo "Conversation $conversation_id" > "$temp_file"
    echo "" >> "$temp_file"
    
    # First, collect all messages using pagination
    > "$messages_file"  # Clear messages file
    while true; do
        local url="$CHATWOOT_BASE_URL/accounts/$ACCOUNT_ID/conversations/$conversation_id/messages"
        if [ -n "$before_id" ]; then
            url="${url}?before=${before_id}"
            echo "  Fetching messages before ID: $before_id"
        else
            echo "  Fetching first page of messages"
        fi

        response=$(curl -s -H "api_access_token: $API_TOKEN" "$url")
        
        # Check for errors
        if echo "$response" | jq -e '.error' > /dev/null; then
            echo "Error fetching messages for conversation $conversation_id: $(echo "$response" | jq -r '.error')"
            return
        fi

        # Check if payload is empty
        payload_size=$(echo "$response" | jq '.payload | length')
        if [ "$payload_size" -eq 0 ]; then
            echo "  Reached beginning of conversation"
            break
        fi

        # Get the ID of the last message for next pagination
        before_id=$(echo "$response" | jq -r '.payload[0].id')

        # Store messages with their IDs in temporary file
        echo "$response" | jq -c '.payload[]' | while IFS= read -r message; do
            id=$(echo "$message" | jq -r '.id')
            echo "$id $message" >> "$messages_file"
        done
    done

    # Sort messages by ID and process them
    sort -n "$messages_file" | while IFS= read -r line; do
        message=$(echo "$line" | cut -d' ' -f2-)
        message_type=$(echo "$message" | jq -r '.message_type')
        sender_type=$(echo "$message" | jq -r '.sender.type // empty')
        content=$(echo "$message" | jq -r '.content // empty')
        
        # Skip system messages and empty content
        if [ "$message_type" -eq 2 ] || [ "$content" = "null" ] || [ -z "$content" ]; then
            continue
        fi
        
        # Format the message based on sender type
        if [ "$sender_type" = "contact" ]; then
            echo "Customer: $content" >> "$temp_file"
        elif [ "$sender_type" = "user" ]; then
            echo "Agent: $content" >> "$temp_file"
        fi
    done
    
    # Add separator
    echo "" >> "$temp_file"
    echo "-------------------" >> "$temp_file"
    echo "" >> "$temp_file"

    # Clean up messages file
    rm -f "$messages_file"

    echo "  Completed processing conversation $conversation_id"
}
export -f process_conversation
export CHATWOOT_BASE_URL ACCOUNT_ID API_TOKEN TEMP_DIR

# Fetch conversations
page=1
conversation_ids=()

while true; do
    echo "Fetching conversations page $page..."
    response=$(curl -s -H "api_access_token: $API_TOKEN" \
        "$CHATWOOT_BASE_URL/accounts/$ACCOUNT_ID/conversations?page=$page")
    
    # Check for errors
    if echo "$response" | jq -e '.error' > /dev/null; then
        echo "Error fetching conversations: $(echo "$response" | jq -r '.error')"
        break
    fi

    # Check if payload is empty (reached end of conversations)
    payload_size=$(echo "$response" | jq '.data.payload | length')
    if [ "$payload_size" -eq 0 ]; then
        echo "Reached end of conversations at page $page"
        break
    fi

    # Extract conversation IDs from this page
    while IFS= read -r conversation; do
        conversation_id=$(echo "$conversation" | jq -r '.id')
        conversation_ids+=("$conversation_id")
        if [ "$TEST_MODE" = true ] && [ ${#conversation_ids[@]} -ge $MAX_TEST_CONVERSATIONS ]; then
            break 2
        fi
    done < <(echo "$response" | jq -c '.data.payload[]')

    page=$((page + 1))
done

# Process conversations in parallel
echo "Processing ${#conversation_ids[@]} conversations in parallel..."
printf "%s\n" "${conversation_ids[@]}" | parallel -j "$MAX_PARALLEL_JOBS" process_conversation

# Combine all temp files in order
for id in "${conversation_ids[@]}"; do
    cat "$TEMP_DIR/$id.txt" >> "$OUTPUT_FILE"
done

# Cleanup
rm -rf "$TEMP_DIR"

echo "Download complete! Data has been saved to $OUTPUT_FILE" 