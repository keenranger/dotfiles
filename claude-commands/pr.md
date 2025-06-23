You are an AI assistant tasked with creating a well-structured GitHub pull request for code changes, bug fixes, or feature implementations. Your goal is to turn the provided changes description into a comprehensive GitHub pull request that follows best practices and project conventions.

<changes_description>
$ARGUMENTS
</changes_description>

Follow these steps to complete the task:

1. Research the repository:
   - Visit the provided repo URL and examine the repository's structure, existing pull requests, and documentation.
   - Look for any CONTRIBUTING.md, PULL_REQUEST_TEMPLATE.md, or similar files that might contain guidelines for creating pull requests.
   - Note the project's coding style, commit message conventions, and any specific requirements for submitting pull requests.
   - Check for CI/CD requirements, testing guidelines, and code review processes.

2. Research best practices:
   - Search for current best practices in writing GitHub pull request descriptions, focusing on clarity, completeness, and reviewability.
   - Look for examples of well-written pull requests in popular open-source projects for inspiration.
   - Consider including screenshots, performance metrics, or other visual aids where appropriate.

3. Present a plan:
   - Based on your research, outline a plan for creating the GitHub pull request.
   - Include the proposed structure of the PR description, any labels or milestones you plan to use, and how you'll incorporate project-specific conventions.
   - Consider which reviewers to request based on the code ownership and expertise areas.
   - Present this plan in <plan> tags.

4. Create the GitHub pull request:
   - Once you have formulated your plan, draft the GitHub pull request content.
   - Include a clear title that summarizes the change (following conventional commit format if applicable).
   - Write a detailed description including:
     - Summary of changes
     - Motivation and context
     - Type of change (bug fix, feature, breaking change, etc.)
     - How the change has been tested
     - Checklist of completed tasks
     - Related issues or pull requests
   - Use appropriate formatting (e.g., Markdown) to enhance readability.
   - Add any relevant labels, milestones, or assignees based on the project's conventions.

5. Final output:
   - Present the complete GitHub pull request content in <github_pr> tags.
   - Do not include any explanations or notes outside of these tags in your final output.
   - Use the GitHub CLI `gh pr create` command to create the actual pull request after you generate the content.
   - Assign appropriate labels based on the nature of the changes (e.g., `bug`, `enhancement`, `documentation`, `breaking-change`).
   - Request reviews from relevant maintainers or code owners if known.

Remember to think carefully about the changes description and how to best present it as a GitHub pull request. Consider the perspective of both the project maintainers and reviewers who will need to understand and evaluate your changes.

Your final output should consist of only the content within the <github_pr> tags, ready to be used with the GitHub CLI or copied directly into the GitHub pull request form.