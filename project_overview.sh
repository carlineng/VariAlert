#!/bin/bash
# This script outputs the structure and contents of your Xcode project.
# It should be run from the root directory where your .xcodeproj file lives.
# It produces an output that is meant to be loaded into the context of an LLM

# Name of the output file
OUTPUT_FILE="project_overview.txt"

# Clear or create the output file
: > "$OUTPUT_FILE"

# Print the Project Structure section header
{
  echo "Project Structure"
  echo "================="
} >> "$OUTPUT_FILE"

# If the 'tree' command is available, use it; otherwise fallback to 'find'
if command -v tree &>/dev/null; then
  tree >> "$OUTPUT_FILE"
else
  echo "'tree' command not found. Using 'find' instead." >> "$OUTPUT_FILE"
  find . -print >> "$OUTPUT_FILE"
fi

# Add a blank line and then the Project Contents section header
{
  echo ""
  echo "Project Contents"
  echo "================"
} >> "$OUTPUT_FILE"

# Loop over each .swift file in the project
# (Feel free to modify the find command if you only want to include certain files.)
while IFS= read -r -d '' swiftFile; do
  {
    echo ""
    echo "----- ${swiftFile} -----"
    echo "----------------------------------------"
    cat "$swiftFile"
    echo "----------------------------------------"
    echo ""
  } >> "$OUTPUT_FILE"
done < <(find . -type f -name "*.swift" -print0)

echo "Output written to $OUTPUT_FILE"
