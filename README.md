# hms-build-changed-charts-action

## Building container image for local use
To enable locally building HMS helm charts the container image that is used by this action must be locally built and tagged. The container image is normally built on demand when this action is referenced by a Github Action workflow. 

The following command will create a local copy of the container image used by this action with the tag `hms-build-changed-charts-action`:
```bash
$ make image
```