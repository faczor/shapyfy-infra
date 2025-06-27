# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is an infrastructure directory containing server credentials and configuration files for the Shapyfy project.


## Security Considerations

- This directory contains sensitive server credentials in the `server-credentials` file
- Never commit, modify, or expose the contents of credential files
- Always treat any files in this directory as potentially sensitive infrastructure dataa

## Server Information

The infrastructure uses a VPS setup with SSH access on a non-standard port. Server credentials are stored in the `server-credentials` file for authorized access only.

The server has:
- Docker installed
- Zsh shell configured