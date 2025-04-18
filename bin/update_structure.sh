#!/bin/bash
# save to .scripts/update_structure.sh
# best way to use is with tree: `brew install tree`

# Create the output file with header
echo "---" > .cursor/rules/structure.mdc
echo "description: Project structure" >> .cursor/rules/structure.mdc
echo "globs: *" >> .cursor/rules/structure.mdc
echo "alwaysApply: true" >> .cursor/structure/structure.mdc
echo "---" >> .cursor/rules/structure.mdc
echo "" >> .cursor/rules/structure.mdc
echo "# Project Structure" > .cursor/rules/structure.mdc
echo "" >> .cursor/rules/structure.mdc
echo "\`\`\`" >> .cursor/rules/structure.mdc

# Check if tree command is available
if command -v tree &> /dev/null; then
  # Use tree command for better visualization
  git ls-files --others --exclude-standard --cached | tree --fromfile -a >> .cursor/rules/structure.mdc
  echo "Using tree command for structure visualization."
else
  # Fallback to the alternative approach if tree is not available
  echo "Tree command not found. Using fallback approach."

  # Get all files from git (respecting .gitignore)
  git ls-files --others --exclude-standard --cached | sort > /tmp/files_list.txt

  # Create a simple tree structure
  echo "." > /tmp/tree_items.txt

  # Process each file to build the tree
  while read -r file; do
    # Skip directories
    if [[ -d "$file" ]]; then continue; fi

    # Add the file to the tree
    echo "$file" >> /tmp/tree_items.txt

    # Add all parent directories
    dir="$file"
    while [[ "$dir" != "." ]]; do
      dir=$(dirname "$dir")
      echo "$dir" >> /tmp/tree_items.txt
    done
  done < /tmp/files_list.txt

  # Sort and remove duplicates
  sort -u /tmp/tree_items.txt > /tmp/tree_sorted.txt
  mv /tmp/tree_sorted.txt /tmp/tree_items.txt

  # Simple tree drawing approach
  prev_dirs=()

  while read -r item; do
    # Skip the root
    if [[ "$item" == "." ]]; then
      continue
    fi

    # Determine if it's a file or directory
    if [[ -f "$item" ]]; then
      is_dir=0
      name=$(basename "$item")
    else
      is_dir=1
      name="$(basename "$item")/"
    fi

    # Split path into components
    IFS='/' read -ra path_parts <<< "$item"

    # Calculate depth (number of path components minus 1)
    depth=$((${#path_parts[@]} - 1))

    # Find common prefix with previous path
    common=0
    if [[ ${#prev_dirs[@]} -gt 0 ]]; then
      for ((i=0; i<depth && i<${#prev_dirs[@]}; i++)); do
        if [[ "${path_parts[$i]}" == "${prev_dirs[$i]}" ]]; then
          ((common++))
        else
          break
        fi
      done
    fi

    # Build the prefix
    prefix=""
    for ((i=0; i<depth; i++)); do
      if [[ $i -lt $common ]]; then
        # Check if this component has more siblings
        has_more=0
        for next in $(grep "^$(dirname "$item")/" /tmp/tree_items.txt); do
          if [[ "$next" > "$item" ]]; then
            has_more=1
            break
          fi
        done

        if [[ $has_more -eq 1 ]]; then
          prefix="${prefix}│   "
        else
          prefix="${prefix}    "
        fi
      else
        prefix="${prefix}    "
      fi
    done

    # Determine if this is the last item in its directory
    is_last=1
    dir=$(dirname "$item")
    for next in $(grep "^$dir/" /tmp/tree_items.txt); do
      if [[ "$next" > "$item" ]]; then
        is_last=0
        break
      fi
    done

    # Choose the connector
    if [[ $is_last -eq 1 ]]; then
      connector="└── "
    else
      connector="├── "
    fi

    # Output the item
    echo "${prefix}${connector}${name}" >> .cursor/rules/structure.mdc

    # Save current path for next iteration
    prev_dirs=("${path_parts[@]}")

  done < /tmp/tree_items.txt

  # Clean up
  rm -f /tmp/files_list.txt /tmp/tree_items.txt
fi

# Close the code block
echo "\`\`\`" >> .cursor/rules/structure.mdc

echo "Project structure has been updated in .cursor/rules/structure.mdc"