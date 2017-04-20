# EEA WWW - Volumes

Prepare Docker volumes needed by **EEA WWW** deployment.

## Dependencies

* **Rancher NFS** (optional)

## Install

* Make sure that **Rancher NFS** is deployed and running if you're going to use `rancher-nfs` with **NFS Volume Driver**, otherwise use `local`.
* Choose **hosts** (labels) where to create PostgreSQL DB related volumes if used `local` with **DB Volume Driver** (recommended).
* Click the **Launch** button.
