# Create a private GitHub repository

Use this when the owner has authorized the repository name and publication of the project to private GitHub. The new-project bootstrap already performs these steps.

```prompt
Connect this project to GitHub using the approved repository name.

1. Inspect existing remotes and repository state. Do not overwrite a remote or create a duplicate repository. If needed, create a PRIVATE repository.
2. Verify GitHub visibility is PRIVATE before pushing business context. Keep .business/ tracked for the owner's history and backup. Never untrack or ignore it as part of private-company setup.
3. Review staged changes and run the secret scanner. Never commit .env, local credentials/settings, dependencies or credentials embedded in source. Stage intended files by name.
4. Commit and push within the authorized scope. Report failures without claiming success; preserve local work.
5. Verify the remote commit and show the repository link.
```

Private visibility does not make secrets safe to commit. Do not change the repository to public without an explicit review of business data and Git history.
