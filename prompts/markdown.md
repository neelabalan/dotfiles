# Markdown writing guidelines

### Critical: heading level rule

- Never use even-numbered heading levels (##, ####, ######).
- Always use odd-numbered heading levels (#, ###, #####).
- Examples:
    - correct: `# Title`, `### Section`, `##### Subsection`
    - wrong: `## Title`, `#### Section`, `###### Subsection`
- Check every heading before finishing. Convert any even-level heading to the nearest odd level.
- Don't skip heading levels (e.g. don't jump from `#` to `#####` without a `###` in between).

### Style principles

- No emojis anywhere in the document.
- Avoid bold text (`**bold**` or `__bold__`) unless it's needed for critical emphasis.
- Prefer bullet points and indentation over adding more headings.
- Use `-` for unordered lists.
- Balance bullets with prose - use paragraphs where the explanation flows naturally as sentences.
- Use backticks for code snippets, variable names, file paths, technical terms, and commands.
- Always specify the language in code blocks for syntax highlighting (e.g. ```python, ```bash).
- Keep writing concise and direct.

### Document structure
- Use headings sparingly, prefer nested bullet points for sub-topics.
- Place footnotes at the very end of the document.
- Example structure:
    ```markdown
    # Main Topic
    
    Brief introduction paragraph explaining the main concept.
    
    ### Key Points
    - First point with explanation
        - Nested detail
        - Another nested detail
    - Second point
    - Third point with reference[^1]
    
    ### Implementation Details
    
    When describing the process, use paragraphs naturally.
    
    [^1]: Source or additional context
    ```

### References and citations
- Use footnotes for citations and additional context when appropriate
- Format: `[^1]` in text, `[^1]: Reference details` at document end
- Use hyperlinks for web references: `[description](url)`

### Diagrams
- Use mermaid diagrams when visualizing flows, relationships, or architectures
- Examples: flowcharts, sequence diagrams, class diagrams, state diagrams
- Keep diagrams simple and focused on the key concepts