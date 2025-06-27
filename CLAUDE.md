# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is an infrastructure directory containing server credentials and configuration files for the Shapyfy project.


## Security Considerations

- This directory contains sensitive server credentials in the `server-credentials` file
- Never commit, modify, or expose the contents of credential files
- Always treat any files in this directory as potentially sensitive infrastructure data

## Server Information

The infrastructure uses a VPS setup with SSH access on a non-standard port. Server credentials are stored in the `server-credentials` file for authorized access only.

The server has:
- K3D (Kubernetes in Docker) installed (and we want to use it)
- Docker installed
- Zsh shell configured

We are building terraform scripts to automate the deployment of the Shapyfy project on this server.
This terraform is creating K3D clusters and deploying the Shapyfy project on them.
All terraform changes will be deployed on remote server.

Checklist for changes:
1. Will this change work on K3D?
2. Will this change work with 1 CPU and 4GB RAM?
3. Is file added to the git?
4. Verify if proper ports of the server are used

Port lokalny	Port zewnętrzny	            Akcja
20247	        srv35.mikr.us:20247		    TCP/UDP
30247	        srv35.mikr.us:30247 	    TCP/UDP
40086	        srv35.mikr.us:40086	          UDP
40087	        srv35.mikr.us:40087	          UDP
40088	        srv35.mikr.us:40088	          UDP
