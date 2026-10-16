# Deliverable 1: Project Setup and Team Collaboration

## 1. Purpose

Deliverable 1 focused on establishing a shared GitHub group project, ensuring that each group member could work with the repository locally, practising collaborative Git workflows, and organising the team's work through a Trello board.

The assessment covered the following activities:

- Establishing a shared GitHub repository for the group project.
- Cloning the repository onto each member's computer.
- Practising collaborative changes using test files.
- Creating individual branches, pushing changes, and merging changes into `main`.
- Organising and coordinating team activities through Trello.

This document records the project's setup, the collaboration exercises, and the branching strategy used to organise team contributions.

## 2. Shared GitHub Repository

The team used a shared GitHub repository for the Christchurch Rental Market Analysis project, named `christchurch_rentalmarket_analysis`.

The repository provides a central location for project files, supports collaboration between team members, and maintains a version history of changes through Git.

The project was configured as an R project with supporting files and directories for development and reproducibility:

- `christchurch_rentalmarket_analysis.Rproj` — the RStudio project file.
- `.gitignore` — specifies files that should be excluded from version control.
- `renv/` and `renv.lock` — support the management and recording of R package dependencies.
- `R/` — contains R scripts used for data preparation, analysis, and other project tasks.
- Data directories — organise project datasets.
- Documentation directories — contain project-level and deliverable-specific documentation.
- Output directories — organise generated results and other project outputs.

Opening `christchurch_rentalmarket_analysis.Rproj` in RStudio establishes the project as the working context and supports the use of project-relative paths.

The `renv` configuration helps team members maintain a consistent R package environment. However, files excluded by `.gitignore`, including local datasets or credentials where applicable, may require separate setup.

## 3. Cloning and Setting Up the Repository

Each group member was required to clone the shared repository onto their own computer. Cloning creates a local copy of the repository that can be used for development and synchronised with GitHub.

The recommended setup procedure is:

1. Clone the shared GitHub repository.
2. Open the cloned repository in the development environment.
3. Open `christchurch_rentalmarket_analysis.Rproj` in RStudio.
4. Confirm that the working directory is the repository root.
5. Run `renv::restore()` in the R console when the project package environment needs to be restored.
6. Confirm that Git recognises the repository and that changes can be committed and synchronised with GitHub.

Cloning the repository does not automatically retrieve files intentionally excluded from version control. Any required local datasets, credentials, or other excluded resources must be supplied or configured separately.

## 4. Collaborative Test-File Exercise

The assessment required the team to practise collaboration by working with test files in the shared repository.

The team created the following test files on their respective branches:

- `test_1.R`
- `test_2.R`
- `test_3.R`

These files were committed and pushed to GitHub as part of the collaboration exercise. They were subsequently deleted during the cleanup process in later deliverables.

The exercise was intended to practise the following collaboration cycle:

1. Pull the latest changes from the shared repository.
2. Create or edit a test file.
3. Review the changes.
4. Stage the changes for commit.
5. Commit the changes with a descriptive commit message.
6. Push the changes to the appropriate remote branch.
7. Retrieve the latest shared changes to keep the local repository up to date.

The assessment also required members to practise pushing changes to `main` and retrieving the updated shared file. The creation of the individual test files formed part of the team's branching and collaboration practice.

These exercises provided practical experience with synchronising local repositories, sharing changes, and maintaining a common project version.

## 5. Repository Branching Strategy and Access Control

The team organised its Git workflow around individual development branches and a shared integration branch. Pooja manages the repository and controls updates to `main`, while Sahil and Claudia contribute through `staging`.

### 5.1 Branch Structure

The branch structure used for the project consists of the following branches:

| Branch    | Purpose                                                                  |
| --------- | ------------------------------------------------------------------------ |
| `main`    | Primary branch containing the final, integrated project version.         |
| `staging` | Shared integration branch for combining and checking team contributions. |
| `pooja`   | Individual working branch for Pooja's contributions.                     |
| `sahil`   | Individual working branch for Sahil's contributions.                     |
| `claudia` | Individual working branch for Claudia's contributions.                   |

Individual branches allow team members to work on their contributions separately. The shared `staging` branch provides a place to combine contributions before integrating validated changes into `main`.

### 5.2 Integration Workflow

The team's intended integration workflow is:

**Individual working branches → `staging` → `main`**

The workflow is organised as follows:

1. **Individual development:** Each team member works on their respective branch.
2. **Contribution to staging:** Pooja, Sahil and Claudia push their changes to `staging` for integration with the team's work.
3. **Integration and validation:** Changes in `staging` are checked for conflicts, errors, and unintended modifications.
4. **Repository manager review:** Pooja reviews the integrated changes and determines when they are ready for the primary branch.
5. **Update main:** Pooja pushes approved changes to `main`, which contains the final, integrated project version.

This workflow separates individual development from shared integration and centralises updates to `main`.

### 5.3 Example Individual Branch Workflow

The following commands illustrate how a team member can update their local repository, create an individual branch, make changes, and push the branch to GitHub.

```bash
git switch main
git pull origin main
git switch -c <your-branch-name>

# Edit the relevant project files

git add <file-or-directory>
git commit -m "Describe the changes"
git push -u origin <your-branch-name>
```

Replace `<your-branch-name>` with the appropriate branch name, such as `pooja`, `sahil`, or `claudia`, where applicable.

After pushing their changes, team members can integrate their work into `staging` through the team's agreed process. Once the integrated changes have been reviewed and validated, Pooja manages their incorporation into `main`.

Before integrating changes, members should check that they are working on the correct branch and that their changes do not unintentionally overwrite other contributions.

### 5.4 Repository Management and Access Control

The team uses a centralised repository-management arrangement to control changes to the main project branch.

- **Pooja — GitHub Repository Manager:** Pooja manages the repository and is the only team member permitted to push directly to `main`.
- **Sahil — Team Contributor:** Sahil contributes changes through `staging`.
- **Claudia — Team Contributor:** Claudia contributes changes through `staging`.
- **`staging` — Shared Integration Branch:** Team members use this branch to contribute and combine their work before it is incorporated into `main`.
- **`main` — Primary Project Branch:** This branch contains the final, integrated project version. Updates are managed by Pooja.

This arrangement separates contribution from final integration. Sahil and Claudia can contribute to shared project development without directly modifying `main`, while Pooja maintains responsibility for updates to the primary branch.

Repository permissions and branch protection rules determine whether these restrictions are technically enforced by GitHub. Permission to push directly to `main` is distinct from permission to merge a pull request into `main`. The repository settings should be checked to confirm that the configured permissions match the team's intended workflow.

### 5.5 Rationale for the Branching Strategy

The branching strategy supports collaboration and project quality in several ways:

- **Isolation:** Individual branches reduce interference between parallel contributions.
- **Integration:** `staging` provides a shared point for combining work.
- **Centralised management:** Pooja coordinates the incorporation of changes into `main`.
- **Traceability:** Git history records commits and branch integration.
- **Risk reduction:** Separating development from the final branch reduces the likelihood of unreviewed changes reaching `main`.

## 6. Team Project Management: Trello

The team used Trello to organise and coordinate project work, Sahil and Pooja manage this board.

**Board:** [GitHub Project — Trello](https://trello.com/b/OlHUSILy/github-project)

The board provides a shared space for tracking project tasks and coordinating contributions. Its current cards, lists, assignments, and progress can be viewed directly on Trello.

Trello complements GitHub: Trello supports task coordination, while GitHub manages source code, version history, and branch integration.

## 7. Significance of the Setup and Collaboration Practices

The activities undertaken for Deliverable 1 established the foundations for collaborative project development.

- **Shared source control:** GitHub provides a common repository and records changes to project files.
- **Local development:** Each member can work on their own computer using the shared repository.
- **Traceability:** Commits record changes and make their history available for review.
- **Parallel development:** Individual branches allow members to work independently.
- **Controlled integration:** `staging` provides a checkpoint for combining and validating contributions before final integration.
- **Centralised repository management:** Pooja manages updates to `main`, separating team contributions from final integration.
- **Team coordination:** Trello provides a shared space for organising and tracking tasks.
- **Reproducibility:** The R project file and `renv` configuration help maintain a consistent development environment.

Together, these practices support an organised, traceable, and maintainable team workflow.

## 8. Related Project Resources

- **Main project overview:** `README.md` at the repository root.
- **Project-level documentation:** `Docs/project/`, subject to the final repository structure.
- **Deliverable documentation:** `Docs/deliverables/`.
- **Team task board:** [GitHub Project — Trello](https://trello.com/b/OlHUSILy/github-project).
