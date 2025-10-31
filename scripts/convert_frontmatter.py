#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime

def convert_yaml_to_toml(content):
    # Extract YAML front matter
    yaml_match = re.match(r'^---\s*\n(.*?)\n---\s*\n(.*)', content, re.DOTALL)
    if not yaml_match:
        return None, None
    
    yaml_content = yaml_match.group(1)
    rest_content = yaml_match.group(2)
    
    # Parse YAML-style lines into a dict
    frontmatter = {}
    for line in yaml_content.strip().split('\n'):
        line = line.strip()
        if ':' in line:
            key, value = [x.strip() for x in line.split(':', 1)]
            # Convert arrays
            if value.startswith('[') and value.endswith(']'):
                value = [x.strip() for x in value[1:-1].split(',')]
                frontmatter[key] = value
            else:
                frontmatter[key] = value.strip(' "\'')
    
    # Convert to TOML format
    toml_lines = ['+++']
    
    # Handle date first if present
    if 'date' in frontmatter:
        toml_lines.append(f'date = {frontmatter["date"]}')
        del frontmatter['date']
    
    # Handle title
    if 'title' in frontmatter:
        title = frontmatter['title'].replace('"', '\\"')  # Escape quotes
        toml_lines.append(f'title = "{title}"')
        del frontmatter['title']
    
    # Handle taxonomies
    taxonomies = []
    if 'categories' in frontmatter:
        cats = frontmatter['categories']
        if isinstance(cats, str):
            cats = [cats]
        taxonomies.append(f'taxonomies.categories = {cats}')
        del frontmatter['categories']
    
    # Add remaining fields
    for key, value in frontmatter.items():
        if isinstance(value, list):
            toml_lines.append(f'{key} = {value}')
        else:
            toml_lines.append(f'{key} = "{value}"')
    
    # Add taxonomies at the end
    toml_lines.extend(taxonomies)
    
    toml_lines.append('+++')
    
    return '\n'.join(toml_lines), rest_content

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Convert content
        toml_frontmatter, rest_content = convert_yaml_to_toml(content)
        if not toml_frontmatter:
            print(f"Skipping {filepath} - no YAML front matter found")
            return False
        
        # Write back
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(toml_frontmatter + '\n\n' + rest_content)
        
        print(f"Converted {filepath}")
        return True
        
    except Exception as e:
        print(f"Error processing {filepath}: {str(e)}")
        return False

def main():
    posts_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'content', 'posts')
    success = 0
    failed = 0
    
    for filename in os.listdir(posts_dir):
        if filename.endswith('.md') and filename != '_index.md':
            filepath = os.path.join(posts_dir, filename)
            if process_file(filepath):
                success += 1
            else:
                failed += 1
    
    print(f"\nConverted {success} files successfully.")
    if failed > 0:
        print(f"Failed to convert {failed} files.")
        sys.exit(1)

if __name__ == '__main__':
    main()