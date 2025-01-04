#!/bin/bash

# Base URL for raw GitHub content
BASE_URL="https://raw.githubusercontent.com/activepieces/activepieces/main/docs/resources"

# Create directories
mkdir -p resources/{videos,images}

echo "Downloading resources..."

# Download MP4 files
cd resources/videos
curl -LO "$BASE_URL/passing-data-3steps.mp4"
curl -LO "$BASE_URL/passing-data-data-to-insert-panel.mp4"
curl -LO "$BASE_URL/passing-data-dynamic-value.mp4"
curl -LO "$BASE_URL/passing-data-load-data.mp4"
curl -LO "$BASE_URL/passing-data-main-insert-data-example.mp4"

# Download GIFs
cd ../images
curl -LO "$BASE_URL/passing-data.gif"
curl -LO "$BASE_URL/scale-pieces-cli.gif"
curl -LO "$BASE_URL/templates.gif"
curl -LO "$BASE_URL/visual-builder.gif"

# Download PNGs
curl -LO "$BASE_URL/architecture.png"
curl -LO "$BASE_URL/banner.png"
curl -LO "$BASE_URL/create-action.png"
curl -LO "$BASE_URL/crowdin-translate-all.png"
curl -LO "$BASE_URL/crowdin.png"
curl -LO "$BASE_URL/flow-history.png"
curl -LO "$BASE_URL/flow-parts.png"
curl -LO "$BASE_URL/passing-data-test-step-first.png"
curl -LO "$BASE_URL/publish-flow.png"
curl -LO "$BASE_URL/unified-ai.png"
curl -LO "$BASE_URL/worker-token.png"
curl -LO "$BASE_URL/workers.png"

# Create README with attribution
cd ..
cat > README.md << EOL
# Resources Attribution

These resources are from the official Activepieces documentation repository:
https://github.com/activepieces/activepieces/tree/main/docs/resources

All rights belong to Activepieces (https://www.activepieces.com).

## Usage Guidelines
- These resources are used for documentation purposes only
- Maintain proper attribution to Activepieces
- Follow Activepieces' MIT license terms
EOL

echo "Done downloading resources!" 