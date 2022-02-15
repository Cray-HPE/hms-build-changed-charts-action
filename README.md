# hms-build-changed-charts-action

- [hms-build-changed-charts-action](#hms-build-changed-charts-action)
  - [Overview](#overview)
    - [update-ct-config-with-chart-dirs.sh](#update-ct-config-with-chart-dirssh)
    - [build_changed_charts.sh](#build_changed_chartssh)
    - [detect_changed_charts.sh](#detect_changed_chartssh)
    - [build_chart.sh](#build_chartsh)
  - [Action Inputs](#action-inputs)
  - [Example Usage](#example-usage)
  - [Building HMS Helm charts locally](#building-hms-helm-charts-locally)

## Overview
This is a [Docker based Github Action](https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action) to perform the process of building HMS Helm charts within a HMS Helm chart repository. The container image used by this action is based on the [hms-build-environment](https://github.com/Cray-HPE/hms-build-environment) container image.

This action is composed up by a collection of bash scripts to build and package Helm charts according ot the [HMS Chart Versioning strategy](https://github.com/Cray-HPE/hms-architecture/blob/develop/build/Chart_versioning_rules.md).

### update-ct-config-with-chart-dirs.sh
Dynamically configures the configuration used by the chart-testing tool to be compatible with the HMS Chart directory structure.

Example invocation:
```bash
export CT_CONFIG=ct.yaml
./update-ct-config-with-chart-dirs.sh charts
```


Example static ct.yaml file present in a [HMS Chart repo](https://github.com/Cray-HPE/hms-sls-charts/blob/main/ct.yaml): 
```yaml
---
chart-dirs: []
chart-repos:
  - cray-algol60=https://artifactory.algol60.net/artifactory/csm-helm-charts
validate-maintainers: false
check-version-increment: false
```

Assuming the chart repositories contains the chart version directories `charts/v1.0` and `charts/v2.0` the updated ct.yaml file would look like the following after update-ct-config-with-chart-dirs.sh is ran:
```yaml
---
chart-dirs:
  - charts/v1.0
  - charts/v2.0
chart-repos:
  - cray-algol60=https://artifactory.algol60.net/artifactory/csm-helm-charts
validate-maintainers: false
check-version-increment: false
```


### build_changed_charts.sh

The build_changes_charts.sh is the main entrypoint for the container image build by this this action that controls how charts are built.

1. First determine the list of charts should be put up for consideration for building using the [detect_changed_charts.sh](#detect_changed_chartssh) script.

2. **For each** chart up for consideration to built perform the following: 
   1. If this is a *stable* built check to see if the expected Git tag exists for the Helm chart. The tag is in the form of `chartname-version`. If the tag already exists, then the chart has been previously built so skip this chart and look at the next one.
    
   2. Build the Helm chart using [build_chart.sh](#build_chartsh).

Example invocation:
```bash
UNSTABLE_BUILD_SUFFIX="-20220201202912+1ad88cd"  
./build_changed_charts.sh charts main
```

### detect_changed_charts.sh
 
The detect_changed_charts.sh script is used to determine the list of charts that are candidates for building.
- For unstable builds the command `ct list-changed --target-branch "$TARGET_BRANCH"` command is used to determine the list of charts that have changed when compared against the target branch (which is typically main). 
- For stable builds all charts in the repo are up for consideration for building. 
  > This is kind of a hack, as we don't have an easy way to determine what charts changed so we will put all charts up for consideration. If a chart already has a git tag, then it will not be built!

The detect_changed_charts.sh script requires two cli arguments. The first one being the charts base directory, and the second being the Git branch name to compare the current branch against.

Example invocation:
```bash
./detect_changed_charts.sh charts main
``` 

This script outputs JSON lines encoded in base64 for each chart that it has determined to have changed (or is a candidate for building) to STDOUT. Informational messages are sent to STDERR so the JSON lines can be piped to JQ for processing.

Each JSON line has a payload similar to the following: 
```json
{
  "Path": "charts/v0.1/cray-power-control",
  "Name": "cray-power-control",
  "Version": "0.1.0",
  "ExpectedGitTag": "cray-power-control-0.1.0",
  "ExpectedGitTagExists": true
}
```

### build_chart.sh

The build_chart.sh script perform the actual job of building and packaging up Helm charts.
1. Download chart dependencies that need to be included in the chart (such as the cray-service chart) using `helm dep up`.

2. If performing an unusable chart build the build suffix for the build will be appended onto the chart version defined in the chart's Chart.yaml.

3. The chart is packaged using a variant of the `helm package` command and is located under the `.packaged` directory in the root of the repo.

Example invocation:
```bash
build_chart.sh charts/v0.1/cray-power-control
```

## Action Inputs
| Name                    | Data Type | Required Field | Default value | Description
| ----------------------- | --------- | -------------- | ------------- | -----------
| `target-branch`         | string    | Required       | `master`      | Git repository branch to check against when determining charts that have changed.
| `unstable-build-suffix` | string    | Optional       | Empty string  | The unstable build suffix is appended to the chart version for unstable builds. If the unstable build suffix is the empty string, then a stable build is performed.## Action Outputs
This action provides no outputs.
## Example Usage

## Building HMS Helm charts locally
All of the HMS Chart repositories contain a Makefile to support building Helm charts locally in a similar way to when this Github Action runs, for example the [Makefile in the hms-power-control-charts repository](https://github.com/Cray-HPE/hms-power-control-charts/blob/main/Makefile). 

To enable locally building HMS helm charts the container image that is used by this action must be locally built and tagged. The container image is normally built on demand when this action is ran, so it is not published to artifactory.

1.  Build a local copy of the container image used by this action with the tag `hms-build-changed-charts-action:local`:
    ```bash
    $ make image
    ```

2.  Now within a locally checked out HMS Helm chart repo (such as hms-power-control-charts) the following functionality is available: 
    1. Build all charts within the repository:
       ```bash
       $ make all-charts
       ```
    2. Build all charts that have changed when compared to the main branch:
       > If the repo was cloned with SSH, then the Docker container performing the build needs those credentials to interact with the locally checked out repo.
       > This has only been tested on macOS, and may not work on other platforms. When on macOS you may need to run `ssh-add` to add your SSH key to your SSH agent.
       ```bash
       $ make changed-charts
       ```
    3. Lint all Helm charts in the repository using chart-testing:
       ```bash
       $ make lint
       ``` 
    4. Clean up modified chart-testing configuration, and remove any packaged Helm chart artifacts.
       ```bash
       $ make clean
       ```