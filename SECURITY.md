# Security Policy

## Scope

This repository contains no application code and no dependencies. Every recipe is a prompt you copy and run against your own codebase, with your own agent and your own credentials. The security surface is therefore the content of the prompts, not anything that executes here.

A reportable issue is a recipe that could cause harm when a user runs it as written:

- A prompt that instructs an agent to read, print, or transmit secrets, `.env` files, or credentials
- A prompt that leads an agent to push, force-push, merge, deploy, or delete without the user asking for it
- A prompt containing a destructive shell command, or one that pipes remote content into a shell
- A prompt built to make an agent exfiltrate source code or send data to a third party
- A malicious or misleading link in a recipe

Not security issues: a recipe that produces low-quality or wrong output, an agent misreading a prompt, or a vulnerability in an agent or CLI that a recipe happens to mention. Report the first as a normal issue, and the last to that tool's own maintainers.

## Reporting

Report vulnerabilities to sg85207@gmail.com. Include the recipe file, the agent you ran it with, and what it did.

Please report privately by email rather than opening a public issue, so that a harmful prompt can be removed before it is advertised. This project is maintained by one person on a best-effort basis; you will get an acknowledgement as soon as the report is seen.

## Supported Versions

Recipes are consumed straight from the default branch. There are no supported older versions: fixes land on `main`, and that is the only version anyone should copy from.
