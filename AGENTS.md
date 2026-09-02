# Holos Music — project working rules

These rules were provided by the user and apply throughout this project.

1. After implementing a change, summarize what was implemented, relevant checks,
   remaining limitations, and what the user can manually review.
2. The user always checks and tests implementations manually. Automated checks
   may support development but never substitute for the user's manual acceptance.
   Record automated verification and user acceptance separately. Do not mark a
   release manually accepted without the user's actual confirmation.
3. Never push to GitHub. The user reviews and pushes changes themselves. Do not
   run git push, publish repository changes, create remote branches or use an API
   as an alternative way of pushing. Local Git inspection/checkpoints are allowed.
   Help with GitHub issues when requested; that does not authorize publishing code.
4. When a download, build or other process requires waiting, stop polling and
   stop further work for that turn. Tell the user what is running, how to monitor
   it and to say "continue" when ready. Leave the process running unless the user
   asks to cancel it. Do not wait repeatedly or create follow-up automations.
5. Prioritize saving the user's tokens. Keep summaries concise, read only relevant
   file sections, avoid repeated checks, unnecessary tool calls and verbose outputs,
   and reuse recorded evidence. Suggest short, practical manual steps when the
   user can complete them more cheaply than an agent-driven workflow. Explain
   what to do and what result to report; do not substitute manual instructions
   for already authorized implementation merely to stop early. Preserve necessary
   verification and report its limits honestly. Do not claim measured token savings
   without usage evidence.
6. Additional user rules may be added later. Update this file when they arrive.

Current scope: Android local FLAC player. Implement one roadmap version at a time.
Reuse selected Mornye code/style for now; redesign comes in later iterations.
Read PROJECT_OVERVIEW.md and FEATURE_ROADMAP.md at session start.
