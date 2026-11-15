---
name: good-to-go
description: Assess whether the current work is ready to proceed when the user asks for a readiness check, resolving consequential uncertainties through one question at a time.
---

Evaluate whether the current work is ready for its intended next step.

1. Infer the intended next step and readiness criteria from the conversation
   and applicable project instructions. If the next step is unclear, resolve
   that first.
2. Inspect available evidence before asking questions. Distinguish known
   defects from missing information.
3. Start with your current verdict and its main reason.
4. Before asking the first question, show a concise, ordered provisional list
   of the consequential questions and its initial total. Include only questions
   not already answered by available evidence. Explain that the list may change
   as answers and new evidence arrive. If no questions remain, give the verdict
   without creating a list merely for ceremony.
5. If missing information could change the verdict, ask the single most
   consequential question. Include your best guess at the answer and a
   brief reason. Label guesses as assumptions, not facts. If there is no
   defensible guess, say so. On every question, show progress as "Question X
   of Y; Z remaining after this", using the current provisional total and
   counting questions actually asked in this assessment.
6. Wait for the user's answer. Incorporate it, reassess, and repeat only
   if another consequential question remains. Use a question tool when
   available and appropriate; otherwise ask in chat and end the turn.
   Maintain the question list across turns. Add, remove, or reorder pending
   questions when warranted, briefly explain any change, and update the total
   and remaining count. Preserve the count of questions already asked; do not
   restart numbering or silently change the total. Reprint the pending list
   when it changes; otherwise the progress indicator is sufficient.
7. Stop when you can give a supported verdict, even if provisional questions
   have fallen away. State any remaining blockers
   or assumptions concisely.

Do not ask questions already answered by available evidence.
Do not invent questions merely to continue the loop.
Do not treat a suggested answer, silence, or elapsed time as user approval.
Assess readiness without expanding scope or executing the next step.
