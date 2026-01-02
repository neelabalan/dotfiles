# Markdown writing guidelines

### CRITICAL: Heading level rule

- NEVER use even-numbered heading levels (##, ####, ######)
- ALWAYS use odd-numbered heading levels (#, ###, #####)
- Examples:
    - CORRECT: `# Title`, `### Section`, `##### Subsection`
    - WRONG: `## Title`, `#### Section`, `###### Subsection`
- Enforcement: Before outputting any markdown, validate that all headings use odd number of hashes. If any even-numbered headings exist, convert them to the nearest odd level.

### Style principles

- No emojis anywhere in the document
- Avoid bold text (`**bold` or `__bold__`) unless absolutely necessary for critical emphasis
- Prefer bullet points and indentation over creating excessive headings
- Balance bullet points with prose - Use paragraphs when explaining concepts that flow naturally as sentences
- Use backticks for code snippets, variable names, file paths, technical terms and commands
- Keep writing concise and direct

### Document structure
- Use headings sparingly - prefer nested bullet points for sub-topics
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